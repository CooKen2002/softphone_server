import os
import re
import json
from typing import Any, Dict, List, Text
from pathlib import Path
import random
import unicodedata

# =========================
# MARK: TOKEN UTILS
# =========================
# =========================
# Trie Node
# =========================


class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False
        self.entity_type = None


class PhraseTrie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, phrase: str, entity_type: str = None):
        node = self.root

        for word in phrase.split():
            if word not in node.children:
                node.children[word] = TrieNode()

            node = node.children[word]

        node.is_end = True
        node.entity_type = entity_type

    def longest_match(self, words, start_idx):
        node = self.root

        longest_end = -1
        longest_entity = ""
        idx = start_idx

        while idx < len(words):
            word = words[idx]

            # Nếu token chứa "_"
            sub_words = word.split("_")

            current_node = node
            matched = True

            for sub_word in sub_words:

                if sub_word not in current_node.children:
                    matched = False
                    break

                current_node = current_node.children[sub_word]

            if not matched:
                break

            node = current_node

            if node.is_end:
                longest_end = idx
                longest_entity = node.entity_type

            idx += 1

        return longest_end, longest_entity


def mark_entities(text: str):
    # 1. SĐT: 10 chữ số bắt đầu bằng 0
    phone_pattern = r"(?<!\d)(0\d{9})(?!\d)"

    # 2. Số lượng: thêm "xe" vào danh sách đơn vị
    amount_pattern = r"(\d+)\s+(vé|người|ghế|suất|chỗ|mình|khách|đứa)"

    # 3. Khoảng thời gian (I_): phải chạy TRƯỚC time_pattern để tránh "1 h nữa" bị nuốt thành T_
    #    Tách prefix thành I_ (interval) để phân biệt với D_ (date)
    interval_pattern = r"(\d{1,2})\s+(h|tiếng|phút)\s+(nữa|sau)"

    # 4. Thời gian giờ cụ thể (T_): negative lookahead tránh "Xh nữa/sau"
    #    "h" theo sau bởi chữ số → "8h30" (giờ:phút), không có chữ số → "8h" (giờ tròn)
    #    Dùng (?=\s|$|[^\d]) để tránh nuốt thêm ký tự khi h đứng cuối cụm (vd "9h sáng")
    time_pattern = (
        r"(\d{1,2}h\d{2}|\d{1,2}\s*(?:giờ|rưỡi|kém)\s*\d{0,2}|\d{1,2}h)(?!\s*(?:nữa|sau))"
    )

    # 5. Ngày/buổi (D_): mở rộng bắt thêm "thứ X", "chủ nhật", "ngày mai/kia" đứng một mình
    #    Quan trọng: đặt nhánh DÀI trước để regex không dừng sớm ở nhánh ngắn hơn
    date_pattern = (
        r"("
        # Nhánh 1: buổi + suffix tuỳ chọn — DÀI NHẤT
        # suffix: "ngày chủ nhật", "ngày mai/kia/DD", "chủ nhật", "thứ X", "mai/kia"
        r"(?:sáng|trưa|chiều|tối|đêm|rạng\s+sáng)"
        r"(?:"
        r"\s+ngày\s+(?:chủ\s+nhật|thứ\s+[2-7]|\d{1,2}|mai|kia|kìa)"  # "sáng ngày chủ nhật / ngày 15 / ngày mai"
        r"|\s+mùng\s+\d{1,2}"  # "sáng mùng 1"
        r"|\s+(?:chủ\s+nhật|thứ\s+[2-7])"  # "sáng chủ nhật / sáng thứ 6"
        r"|\s+(?:mai|kia|kìa)"  # "sáng mai"
        r")?"
        r"|"
        # Nhánh 2: "ngày mai/kia/DD" đứng một mình
        r"ngày\s+(?:mai|kia|kìa|\d{1,2})"
        r"|"
        # Nhánh 3: thứ X / chủ nhật không kèm buổi — NGẮN NHẤT
        r"(?:thứ\s+[2-7]|chủ\s+nhật)"
        r"(?:\s+(?:tuần\s+(?:sau|này|tới)|tới|này))?"
        r")"
    )

    # Thứ tự thay thế: phone → amount → interval → time → date
    text = re.sub(phone_pattern, lambda m: f"P_{m.group(1)}", text)
    text = re.sub(amount_pattern, lambda m: f"A_{m.group(1)}_{m.group(2)}", text)
    text = re.sub(
        interval_pattern, lambda m: f"I_{m.group(1)}_{m.group(2)}_{m.group(3)}", text
    )
    text = re.sub(
        time_pattern, lambda m: f"T_{m.group(1).strip().replace(' ', '_')}", text
    )
    text = re.sub(date_pattern, lambda m: f"D_{m.group(1).replace(' ', '_')}", text)

    return text


def normalize_text(text: str):
    text = text.lower().strip()
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text)

    text = text_to_number(text)

    # "10 giờ 30 phút" / "10 giờ 30" → "10h30"  (phút luôn đúng 2 chữ số)
    text = re.sub(r"(\d{1,2})\s*giờ\s*(\d{2})\s*(?:phút)?", r"\1h\2", text)
    # "10 giờ" (không có phút) → "10h"
    text = re.sub(r"(\d{1,2})\s*giờ", r"\1h", text)

    # "2h0987654321" → "2h 0987654321",  "10h300987654321" → "10h30 0987654321"
    text = re.sub(r"(\d{1,2}h\d{2})(\d+)", r"\1 \2", text)
    text = re.sub(r"(\d{1,2}h)(\d{3,})", r"\1 \2", text)

    # ── Bước 3: chuẩn hóa SĐT — gộp khoảng trắng giữa các chữ số, thêm space 2 phía
    def _normalize_phone(m):
        return " " + m.group(0).replace(" ", "") + " "

    text = re.sub(r"0\s*(?:\d\s*){9}(?!\d)", _normalize_phone, text)

    # ── Bước 4: dọn khoảng trắng thừa
    text = re.sub(r"\s+", " ", text).strip()

    # Địa danh
    if "3 đình" in text:
        text = text.replace("3 đình", "ba đình")
    elif "4 sở" in text:
        text = text.replace("4 sở", "tư sở")

    return text


def text_to_number(text):
    dict_so = {
        "không": 0,
        "một": 1,
        "hai": 2,
        "ba": 3,
        "bốn": 4,
        "tư": 4,
        "năm": 5,
        "lăm": 5,
        "sáu": 6,
        "bẩy": 7,
        "bảy": 7,
        "tám": 8,
        "chín": 9,
        "mười": 10,
    }

    def parse_chunk(word_str):
        words = word_str.lower().split()

        # XỬ LÝ TRƯỜNG HỢP SỐ LẶP (Ví dụ: "ba ba", "năm năm")
        if len(words) == 2 and words[0] == words[1] and words[0] in dict_so:
            val = dict_so[words[0]]
            return str(val * 10 + val)  # 3 * 10 + 3 = 33

        total = 0
        i = 0
        while i < len(words):
            w = words[i]

            # Hàng nghìn
            if w in ["nghìn", "ngàn"]:
                multiplier = dict_so.get(words[i - 1], 1) if i > 0 else 1
                if i > 0 and words[i - 1] in dict_so:
                    total -= dict_so[words[i - 1]]
                total += multiplier * 1000

            # Hàng trăm
            elif w == "trăm":
                multiplier = dict_so.get(words[i - 1], 1) if i > 0 else 1
                if i > 0 and words[i - 1] in dict_so and words[i - 1] != "không":
                    total -= dict_so[words[i - 1]]
                total += (
                    multiplier * 1000 if words[i - 1] == "nghìn" else multiplier * 100
                )

            # Hàng mươi
            elif w == "mươi":
                multiplier = dict_so.get(words[i - 1], 1)
                total -= multiplier
                total += multiplier * 10

            # Hàng mười
            elif w == "mười":
                total += 10

            elif w in ["linh", "lẻ"]:
                pass

            # Số đơn lẻ
            elif w in dict_so:
                if w == "không" and i + 1 < len(words) and words[i + 1] == "trăm":
                    pass
                else:
                    total += dict_so[w]
            i += 1

        return str(total)

    # Regex chứa cụm số lặp ở giữa
    pattern = r"\b(?:(?:một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+(?:nghìn|ngàn)(?:\s+(?:không|một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+trăm)?(?:\s+(?:linh|lẻ|(?:hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+mươi|mười))?(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|tám|chín))?|(?:không|một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+trăm(?:\s+(?:linh|lẻ|(?:hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+mươi|mười))?(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|bẩy|tám|chín))?|(?:không\s+không|một\s+một|hai\s+hai|ba\s+ba|bốn\s+bốn|tư\s+tư|năm\s+năm|sáu\s+sáu|bảy\s+bảy|tám\s+tám|chín\s+chín)|(?:hai|ba|bốn|năm|sáu|bảy|bẩy|tám|chín)\s+mươi(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|bẩy|tám|chín))?|mười\s+(?:một|hai|ba|bốn|lăm|năm|sáu|bảy|bẩy|tám|chín)|không|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|mười)\b"

    return re.sub(pattern, lambda x: parse_chunk(x.group(0)), text, flags=re.IGNORECASE)

# MARK: MAIN: TEST
# print(mark_entities('đặt xe địa điểm 0912345679 xuống bệnh viện tai mũi họng thành phố hồ chí minh đón tại bệnh viện viện tim thành phố hồ chí minh cho an lúc 24h sáng mai đi 100 vé'))
print((normalize_text('ba mươi bẩy')))