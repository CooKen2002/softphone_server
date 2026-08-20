# import json
# import os
# import re

# DICT_DIR = r"D:\wav2vec2"

# DICT_FILES = {
#     "common":    "common_dict.json",
#     "cartype":   "Cartype_dict.json",
#     "location":  "location_dict.json",
#     "time":      "Time_dict.json",
#     "province":  "VietNam_Provinces_dict.json",
# }

# SPECIAL_TOKENS = {"<pad>", "<unk>"}

# # ----------------------------------------------------------------------
# # 1. LOAD DICTIONARIES
# # ----------------------------------------------------------------------
# def load_dicts(dict_dir=DICT_DIR):
#     """Đọc 5 file json -> dict[dict_name][id(str)] = phrase(str)"""
#     all_dicts = {}
#     for name, fname in DICT_FILES.items():
#         path = os.path.join(dict_dir, fname)
#         with open(path, "r", encoding="utf-8") as f:
#             all_dicts[name] = json.load(f)
#     return all_dicts


# # ----------------------------------------------------------------------
# # 2. BUILD "NGÂN HÀNG CỤM TỪ" — tách riêng entry theo SỐ TỪ (word count)
# #    để khi duyệt sliding-window ta chỉ cần so khớp trong đúng nhóm độ dài
# #    -> giảm số lần tính Levenshtein, nhanh hơn nhiều.
# # ----------------------------------------------------------------------
# def build_phrase_bank(all_dicts, exclude=("common",)):
#     """
#     Trả về:
#         phrase_bank[word_count] = [ (dict_name, id, phrase, [tokens]) , ... ]
#         max_len = số từ dài nhất trong toàn bộ dict (để giới hạn cửa sổ trượt)
#     """
#     phrase_bank = {}
#     max_len = 1
#     for dict_name, d in all_dicts.items():
#         if dict_name in exclude:
#             continue
#         for id_, phrase in d.items():
#             if phrase in SPECIAL_TOKENS:
#                 continue
#             tokens = phrase.split()
#             n = len(tokens)
#             max_len = max(max_len, n)
#             phrase_bank.setdefault(n, []).append((dict_name, id_, phrase, tokens))
#     return phrase_bank, max_len


# # ----------------------------------------------------------------------
# # 3. LEVENSHTEIN DISTANCE (tự cài, không cần thư viện ngoài)
# # ----------------------------------------------------------------------
# def levenshtein(a: str, b: str) -> int:
#     if a == b:
#         return 0
#     la, lb = len(a), len(b)
#     if la == 0:
#         return lb
#     if lb == 0:
#         return la
#     prev = list(range(lb + 1))
#     for i in range(1, la + 1):
#         curr = [i] + [0] * lb
#         for j in range(1, lb + 1):
#             cost = 0 if a[i - 1] == b[j - 1] else 1
#             curr[j] = min(
#                 prev[j] + 1,        # xoá
#                 curr[j - 1] + 1,    # thêm
#                 prev[j - 1] + cost  # thay
#             )
#         prev = curr
#     return prev[lb]


# def similarity(a: str, b: str) -> float:
#     """Trả về điểm tương đồng 0..1 (1 = giống hệt)."""
#     if not a and not b:
#         return 1.0
#     dist = levenshtein(a, b)
#     return 1 - dist / max(len(a), len(b))


# # ----------------------------------------------------------------------
# # 4. TIỀN XỬ LÝ CÂU ĐẦU VÀO
# # ----------------------------------------------------------------------
# def normalize(text: str) -> str:
#     text = text.lower().strip()
#     text = re.sub(r"[^\w\sÀ-ỹ]", " ", text)   # bỏ dấu câu, giữ chữ có dấu tiếng Việt
#     text = re.sub(r"\s+", " ", text)
#     return text


# # ----------------------------------------------------------------------
# # 5. SO KHỚP CẤP TỪ (word-level alignment) — thay cho Levenshtein cấp ký tự
# #    trên cả cụm. Mỗi "phần tử" trong DP là 1 TỪ, chi phí thay thế giữa
# #    2 từ = tỉ lệ Levenshtein ký tự giữa chúng (soft cost) -> vừa cho phép
# #    sửa lỗi chính tả TRONG một từ, vừa tránh việc 1 từ chức năng ngắn
# #    ("từ", "về"...) bị "hoà tan" lẫn vào cụm bên cạnh.
# # ----------------------------------------------------------------------
# def word_align_score(cand_tokens, entry_tokens):
#     la, lb = len(cand_tokens), len(entry_tokens)
#     if la == 0 or lb == 0:
#         return 0.0
#     dp = [[0] * (lb + 1) for _ in range(la + 1)]
#     for i in range(la + 1):
#         dp[i][0] = i
#     for j in range(lb + 1):
#         dp[0][j] = j
#     for i in range(1, la + 1):
#         for j in range(1, lb + 1):
#             a, b = cand_tokens[i - 1], entry_tokens[j - 1]
#             sub_cost = 0.0 if a == b else levenshtein(a, b) / max(len(a), len(b))
#             dp[i][j] = min(
#                 dp[i - 1][j] + 1,          # xoá 1 từ
#                 dp[i][j - 1] + 1,          # thêm 1 từ
#                 dp[i - 1][j - 1] + sub_cost,  # thay 1 từ (mềm, theo % lỗi chính tả)
#             )
#     return 1 - dp[la][lb] / max(la, lb)


# # ----------------------------------------------------------------------
# # 6. THUẬT TOÁN CHÍNH — 2 PASS:
# #    Pass 1: fuzzy-match cụm THỰC THỂ (Cartype/location/Time/Province)
# #            chạy TRÊN TOÀN CÂU trước tiên, ưu tiên entry DÀI trước,
# #            dung sai ĐỘ DÀI ±1 từ, so khớp CẤP TỪ (word_align_score)
# #            -> "xe giường nằm" vẫn nhận ra "xe khách giường nằm" dù
# #               thiếu chữ "khách", mà KHÔNG cần tách "xe" ra trước.
# #            -> "từ hà nội" KHÔNG còn bị nuốt nhầm thành "ga hà nội" vì
# #               so khớp cấp từ phạt rất nặng khi "từ" ghép lệch với "ga".
# #    Pass 2: những vị trí còn trống (chưa khớp thực thể nào) ->
# #            thử common_dict (exact trước, fuzzy sau); nếu vẫn không
# #            khớp -> GIỮ NGUYÊN VĂN (raw), không quy về <unk>, để
# #            decode() luôn tái tạo đúng câu gốc, không mất dữ liệu.
# # ----------------------------------------------------------------------
# def encode(text: str, all_dicts, phrase_bank, max_len,
#            entity_threshold: float = 0.7, common_threshold: float = 0.8):
#     tokens = normalize(text).split()
#     n_tokens = len(tokens)
#     common_dict = all_dicts["common"]
#     common_rev = {v: k for k, v in common_dict.items() if v not in SPECIAL_TOKENS}

#     slot = [None] * n_tokens          # None = chưa khớp; ("__merged__",) = đã bị gộp vào match trước
#     consumed_end = [None] * n_tokens

#     # ---- Pass 1: fuzzy multi-word cho TOÀN CÂU, ưu tiên entry dài trước ----
#     i = 0
#     while i < n_tokens:                                    # <-- vòng lặp duyệt từng vị trí bắt đầu
#         best_match, best_score, best_len = None, entity_threshold, 0
#         for entry_len in sorted(phrase_bank.keys(), reverse=True):   # <-- vòng lặp độ dài entry, dài trước
#             for dict_name, id_, phrase, ph_tokens in phrase_bank[entry_len]:  # <-- vòng lặp so khớp entry
#                 for window_len in (entry_len - 1, entry_len, entry_len + 1):  # <-- dung sai ±1 từ
#                     if window_len < 1 or i + window_len > n_tokens:
#                         continue
#                     cand = tokens[i:i + window_len]
#                     score = word_align_score(cand, ph_tokens)
#                     if score > best_score:
#                         best_score = score
#                         best_match = (dict_name, id_, phrase)
#                         best_len = window_len

#         if best_match is not None:
#             dict_name, id_, phrase = best_match
#             slot[i] = (dict_name, id_, phrase)
#             consumed_end[i] = i + best_len
#             for k in range(i + 1, i + best_len):
#                 slot[k] = ("__merged__", None, None)
#                 consumed_end[k] = i + best_len
#             i += best_len
#         else:
#             i += 1

#     # ---- Pass 2: các vị trí còn trống -> common_dict (exact rồi fuzzy) -> raw ----
#     result = []
#     i = 0
#     while i < n_tokens:                                    # <-- vòng lặp gom kết quả cuối
#         s = slot[i]
#         if s is None:
#             word = tokens[i]
#             if word in common_rev:                         # exact-match trước
#                 result.append(("common", common_rev[word], word))
#             else:                                           # fuzzy 1-từ
#                 best_common, best_score = None, common_threshold
#                 for phrase, id_ in common_rev.items():      # <-- vòng lặp fuzzy common 1-từ
#                     if len(phrase.split()) != 1:
#                         continue
#                     sc = similarity(word, phrase)
#                     if sc > best_score:
#                         best_score, best_common = sc, (id_, phrase)
#                 if best_common is not None:
#                     id_, phrase = best_common
#                     result.append(("common", id_, phrase))
#                 else:
#                     # KHÔNG quy về <unk> -> giữ nguyên văn để decode không mất dữ liệu
#                     result.append(("raw", None, word))
#             i += 1
#         elif s[0] == "__merged__":
#             i += 1
#         else:
#             result.append(s)
#             i = consumed_end[i]

#     corrected_text = " ".join(r[2] for r in result)
#     return corrected_text, result


# # ----------------------------------------------------------------------
# # 7. DECODE: tra id -> text; riêng dict_name == "raw" thì lấy thẳng chữ gốc
# #    đã lưu trong encoding (không tra dict) -> không còn mất dữ liệu.
# # ----------------------------------------------------------------------
# def decode(encoded, all_dicts):
#     words = []
#     for dict_name, id_, phrase in encoded:
#         if dict_name == "raw":
#             words.append(phrase)          # giữ nguyên văn, không tra dict
#         else:
#             words.append(all_dicts[dict_name].get(str(id_), phrase))
#     return " ".join(words)


# # ----------------------------------------------------------------------
# # 7. DEMO
# # ----------------------------------------------------------------------
# if __name__ == "__main__":
#     all_dicts = load_dicts(dict_dir=r"D:\wav2vec2")
#     phrase_bank, max_len = build_phrase_bank(all_dicts)

#     test_sentences = [
#         # "cho tôi 1 xe  đi kin mã về hà đông",
#         # "tôi muốn đặt vé xe giường nằm từ hà nội đi đà nẵng lúc tam giờ sáng",
#         # "book giúp tôi vé đi sân bay tân sơn nhât",
#         # "xin chào anh chị cho em hoi ve gia ve",         # câu có nhiều từ hoàn toàn không có trong dict
#         # "đặt dùm tôi vé xe 7 chô đi vinh phuc",
#         "cho tôi 1 xe đi từ nguyễn chí thanh về kin mã lúc chín giờ chiều",
#     ]

#     for s in test_sentences:
#         corrected, encoded = encode(s, all_dicts, phrase_bank, max_len)
#         decoded = decode(encoded, all_dicts)
#         print("=" * 70)
#         print("Input gốc     :", s)
#         print("Encoded       :")
#         # print("Sau khi sửa   :", corrected)
#         for item in encoded:
#             print("   ", item)
#         print("Decode:", decoded)

import json
import os
import re

from config import DICT_DIR, DICT_FILES, SPECIAL_TOKENS
# Mặc định: lấy đúng thư mục chứa file .py này (chạy được trên mọi máy/OS).
# Nếu 5 file json để chỗ khác, sửa lại DICT_DIR = r"D:\wav2vec2\dicts" (Windows)
# hoặc truyền path trực tiếp vào load_dicts(dict_dir=...).



# ----------------------------------------------------------------------
# 1. LOAD DICTIONARIES
# ----------------------------------------------------------------------
def load_dicts(dict_dir: str = None):
    """
        Đọc 5 file json -> dict[dict_name][id(str)] = phrase(str)
        dict_dir: thư mục chứa 5 file json. Nếu None -> dùng DICT_DIR (thư mục chứa script).
    """
    dict_dir = dict_dir or DICT_DIR
    all_dicts = {}
    for name, fname in DICT_FILES.items():
        path = os.path.join(dict_dir, fname)
        with open(path, "r", encoding="utf-8") as f:
            all_dicts[name] = json.load(f)
    return all_dicts

# ----------------------------------------------------------------------
# 2. BUILD "NGÂN HÀNG CỤM TỪ" — tách riêng entry theo SỐ TỪ (word count)
#    để khi duyệt sliding-window ta chỉ cần so khớp trong đúng nhóm độ dài
#    -> giảm số lần tính Levenshtein, nhanh hơn nhiều.
# ----------------------------------------------------------------------
def build_phrase_bank(all_dicts, exclude=("common",)):

    phrase_bank = {}
    max_len = 1
    for dict_name, d in all_dicts.items():
        if dict_name in exclude:
            continue
        for id_, phrase in d.items():
            if phrase in SPECIAL_TOKENS:
                continue
            tokens = phrase.split()
            n = len(tokens)
            max_len = max(max_len, n)
            phrase_bank.setdefault(n, []).append((dict_name, id_, phrase, tokens))
    return phrase_bank, max_len

# ----------------------------------------------------------------------
# 3. LEVENSHTEIN DISTANCE (tự cài, không cần thư viện ngoài)
# ----------------------------------------------------------------------
def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    la, lb = len(a), len(b)
    if la == 0:
        return lb
    if lb == 0:
        return la
    prev = list(range(lb + 1))
    for i in range(1, la + 1):
        curr = [i] + [0] * lb
        for j in range(1, lb + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            curr[j] = min(
                prev[j] + 1,        # xoá
                curr[j - 1] + 1,    # thêm
                prev[j - 1] + cost  # thay
            )
        prev = curr
    return prev[lb]


def similarity(a: str, b: str) -> float:
    """Trả về điểm tương đồng 0..1 (1 = giống hệt)."""
    if not a and not b:
        return 1.0
    dist = levenshtein(a, b)
    return 1 - dist / max(len(a), len(b))


# ----------------------------------------------------------------------
# 4. TIỀN XỬ LÝ CÂU ĐẦU VÀO
# ----------------------------------------------------------------------
def normalize(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\sÀ-ỹ]", " ", text)   # bỏ dấu câu, giữ chữ có dấu tiếng Việt
    text = re.sub(r"\s+", " ", text)
    return text


# ----------------------------------------------------------------------
# 5. SO KHỚP CẤP TỪ (word-level alignment) — thay cho Levenshtein cấp ký tự
#    trên cả cụm. Mỗi "phần tử" trong DP là 1 TỪ, chi phí thay thế giữa
#    2 từ = tỉ lệ Levenshtein ký tự giữa chúng (soft cost) -> vừa cho phép
#    sửa lỗi chính tả TRONG một từ, vừa tránh việc 1 từ chức năng ngắn
#    ("từ", "về"...) bị "hoà tan" lẫn vào cụm bên cạnh.
# ----------------------------------------------------------------------
def word_sub_cost(a: str, b: str) -> float:
    if a == b:
        return 0.0
    ratio = levenshtein(a, b) / max(len(a), len(b))
    if ratio >= 0.6:
        return 2.0
    return ratio


def word_align_score(cand_tokens, entry_tokens):
    la, lb = len(cand_tokens), len(entry_tokens)
    if la == 0 or lb == 0:
        return 0.0
    dp = [[0] * (lb + 1) for _ in range(la + 1)]
    for i in range(la + 1):
        dp[i][0] = i
    for j in range(lb + 1):
        dp[0][j] = j
    for i in range(1, la + 1):
        for j in range(1, lb + 1):
            sub_cost = word_sub_cost(cand_tokens[i - 1], entry_tokens[j - 1])
            dp[i][j] = min(
                dp[i - 1][j] + 1,          # xoá 1 từ
                dp[i][j - 1] + 1,          # thêm 1 từ
                dp[i - 1][j - 1] + sub_cost,  # thay 1 từ (chỉ rẻ khi thật sự là lỗi chính tả)
            )
    return 1 - dp[la][lb] / max(la, lb)


# ----------------------------------------------------------------------
# 6. THUẬT TOÁN CHÍNH — 2 PASS:
#    Pass 1: fuzzy-match cụm THỰC THỂ (Cartype/location/Time/Province)
#            chạy TRÊN TOÀN CÂU trước tiên, ưu tiên entry DÀI trước,
#            dung sai ĐỘ DÀI ±1 từ, so khớp CẤP TỪ (word_align_score)
#            -> "xe giường nằm" vẫn nhận ra "xe khách giường nằm" dù
#               thiếu chữ "khách", mà KHÔNG cần tách "xe" ra trước.
#            -> "từ hà nội" KHÔNG còn bị nuốt nhầm thành "ga hà nội" vì
#               so khớp cấp từ phạt rất nặng khi "từ" ghép lệch với "ga".
#    Pass 2: những vị trí còn trống (chưa khớp thực thể nào) ->
#            thử common_dict (exact trước, fuzzy sau); nếu vẫn không
#            khớp -> GIỮ NGUYÊN VĂN (raw), không quy về <unk>, để
#            decode() luôn tái tạo đúng câu gốc, không mất dữ liệu.
# ----------------------------------------------------------------------
def encode(text: str, all_dicts, phrase_bank, max_len,
           entity_threshold: float = 0.7, common_threshold: float = 0.8):
    tokens = normalize(text).split()
    n_tokens = len(tokens)
    common_dict = all_dicts["common"]
    common_rev = {v: k for k, v in common_dict.items() if v not in SPECIAL_TOKENS}

    slot = [None] * n_tokens          # None = chưa khớp; ("__merged__",) = đã bị gộp vào match trước
    consumed_end = [None] * n_tokens

    # ---- Pass 1: fuzzy multi-word cho TOÀN CÂU, ưu tiên entry dài trước ----
    i = 0
    while i < n_tokens:                                    # <-- vòng lặp duyệt từng vị trí bắt đầu
        best_match, best_score, best_len = None, entity_threshold, 0

        for entry_len in sorted(phrase_bank.keys(), reverse=True):   # <-- vòng lặp độ dài entry, dài trước
            level_match, level_score, level_len = None, entity_threshold, 0
            for dict_name, id_, phrase, ph_tokens in phrase_bank[entry_len]:  # <-- vòng lặp so khớp entry
                for window_len in (entry_len - 1, entry_len):  # <-- CHỈ dung sai -1 (thiếu từ), bỏ +1
                    if window_len < 1 or i + window_len > n_tokens:
                        continue
                    cand = tokens[i:i + window_len]
                    score = word_align_score(cand, ph_tokens)
                    if score > level_score:
                        level_score = score
                        level_match = (dict_name, id_, phrase)
                        level_len = window_len
            if level_match is not None:
                # đã tìm được match ở độ dài entry_len (dài nhất còn khả dĩ)
                # -> DỪNG NGAY, không cho entry ngắn hơn (dù điểm cao hơn) ghi đè
                best_match, best_score, best_len = level_match, level_score, level_len
                break

        if best_match is not None:
            dict_name, id_, phrase = best_match
            slot[i] = (dict_name, id_, phrase)
            consumed_end[i] = i + best_len
            for k in range(i + 1, i + best_len):
                slot[k] = ("__merged__", None, None)
                consumed_end[k] = i + best_len
            i += best_len
        else:
            i += 1

    # ---- Pass 2: các vị trí còn trống -> common_dict (exact rồi fuzzy) -> raw ----
    result = []
    i = 0
    while i < n_tokens:                                    # <-- vòng lặp gom kết quả cuối
        s = slot[i]
        if s is None:
            word = tokens[i]
            if word in common_rev:                         # exact-match trước
                result.append(("common", common_rev[word], word))
            else:                                           # fuzzy 1-từ
                best_common, best_score = None, common_threshold
                for phrase, id_ in common_rev.items():      # <-- vòng lặp fuzzy common 1-từ
                    if len(phrase.split()) != 1:
                        continue
                    sc = similarity(word, phrase)
                    if sc > best_score:
                        best_score, best_common = sc, (id_, phrase)
                if best_common is not None:
                    id_, phrase = best_common
                    result.append(("common", id_, phrase))
                else:
                    # KHÔNG quy về <unk> -> giữ nguyên văn để decode không mất dữ liệu
                    result.append(("raw", None, word))
            i += 1
        elif s[0] == "__merged__":
            i += 1
        else:
            result.append(s)
            i = consumed_end[i]

    corrected_text = " ".join(r[2] for r in result)
    return corrected_text, result


# ----------------------------------------------------------------------
# 7. DECODE: tra id -> text; riêng dict_name == "raw" thì lấy thẳng chữ gốc
#    đã lưu trong encoding (không tra dict) -> không còn mất dữ liệu.
# ----------------------------------------------------------------------
def decode(encoded, all_dicts):
    words = []
    for dict_name, id_, phrase in encoded:
        if dict_name == "raw":
            words.append(phrase)          # giữ nguyên văn, không tra dict
        else:
            words.append(all_dicts[dict_name].get(str(id_), phrase))
    return " ".join(words)

def correct(text: str):
    all_dicts = load_dicts(DICT_DIR)
    phrase_bank, max_len = build_phrase_bank(all_dicts)

    corrected, encoded = encode(text, all_dicts, phrase_bank, max_len)
    print("Input gốc :", text)
    print("Encoded :")
    decoded = decode(encoded, all_dicts)
    for item in encoded:
        print("   ", item)
    return decoded
# ----------------------------------------------------------------------
# 7. DEMO
# ----------------------------------------------------------------------
if __name__ == "__main__":


    test_sentences = [
        # "cho tôi 1 xe  đi kin mã về hà đông",
        # "tôi muốn đặt vé xe giường nằm từ hà nội đi đà nẵng lúc tam giờ sáng",
        # "book giúp tôi vé đi sân bay tân sơn nhât",
        # "xin chào anh chị cho em hoi ve gia ve",
        # "đặt dùm tôi vé xe 7 chô đi vinh phuc",
        "cho tôi 1 xe đi từ n nam về cầu giây lúc chín giờ chiều",
    ]

    for s in test_sentences:
        decoded = correct(s)
        print("Decode :", decoded)