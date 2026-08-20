import json
import os
import unicodedata
from difflib import SequenceMatcher

import numpy as np
import soundfile as sf

from wav2vec import compress_sequence

DICT_FILE = "tokenizer_dict.json"

MODEL_PATH = "wav2vec2_vietnamese.onnx"
AUDIO_FILE = "1.mp3"

CHUNK_LENGTH = 20
MAX_N_SAMPLES = CHUNK_LENGTH * 16000

PAD_ID = 0
UNK_ID = 1

UNK_MARKER = "<unk>"
fuzyy_tokenizer_dict = {
    "0": "<pad>",
    "1": "<unk>",
    "2": "cho",
    "3": "tôi",
    "4": "1",
    "5": "vé",
    "6": "đi",
    "7": "hải",
    "8": "phòng",
    "11": "đặt",
    "12": "giúp",
    "13": "mình",
    "14": "chuyến",
    "15": "xe",
    "16": "mua",
    "17": "khách",
    "18": "từ",
    "19": "đến",
    "20": "quán",
    "21": "thánh",
    "22": "dùm",
    "23": "muốn",
    "24": "cần",
    "25": "chỗ",
    "26": "book",
    "27": "hộ",
    "28": "đò",
    "29": "limousine",
    "30": "bệnh",
    "31": "viện",
    "32": "đa",
    "33": "khoa",
    "34": "tỉnh",
    "37": "vincom",
    "38": "nguyễn",
    "39": "chí",
    "40": "thanh",
    "41": "lấy",
    "42": "tầm",
    "44": "ngày",
    "45": "30",
    "46": "tháng",
    "47": "này",
    "48": "số",
    "50": "tên",
    "51": "ngô",
    "52": "văn",
    "53": "nhé",
    "54": "liên",
    "55": "hệ",
    "56": "điện",
    "57": "thoại",
    "58": "lượng",
    "59": "điểm",
    "60": "đón",
    "61": "về",
    "62": "thời",
    "64": "bao",
    "65": "nhiêu",
    "66": "dừng",
    "67": "ở",
    "68": "kết",
    "69": "thúc",
    "70": "tại",
    "71": "bắt",
    "72": "đầu",
    "73": "bằng",
    "74": "giùm",
    "76": "sài",
    "77": "gòn",
    "78": "an",
    "79": "giang",
    "80": "hà nội",
    "81": "hồ chí minh",
    "82": "đà nẵng",
    "83": "hải phòng",
    "84": "cần thơ",
    "85": "an giang",
    "86": "bà rịa vũng tàu",
    "87": "bắc giang",
    "88": "bắc kạn",
    "89": "bạc liêu",
    "90": "bắc ninh",
    "91": "bến tre",
    "92": "bình định",
    "93": "bình dương",
    "94": "bình phước",
    "95": "bình thuận",
    "96": "cà mau",
    "97": "cao bằng",
    "98": "đắk lắk",
    "99": "đắk nông",
    "100": "điện biên",
    "101": "đồng nai",
    "102": "đồng tháp",
    "103": "gia lai",
    "104": "hà giang",
    "105": "hà nam",
    "106": "hà tĩnh",
    "107": "hải dương",
    "108": "hậu giang",
    "109": "hòa bình",
    "110": "hưng yên",
    "111": "khánh hòa",
    "112": "kiên giang",
    "113": "kon tum",
    "114": "lai châu",
    "115": "lâm đồng",
    "116": "lạng sơn",
    "117": "lào cai",
    "118": "long an",
    "119": "nam định",
    "120": "nghệ an",
    "121": "ninh bình",
    "122": "ninh thuận",
    "123": "phú thọ",
    "124": "phú yên",
    "125": "quảng bình",
    "126": "quảng nam",
    "127": "quảng ngãi",
    "128": "quảng ninh",
    "129": "quảng trị",
    "130": "sóc trăng",
    "131": "sơn la",
    "132": "tây ninh",
    "133": "thái bình",
    "134": "thái nguyên",
    "135": "thanh hóa",
    "136": "thừa thiên huế",
    "137": "tiền giang",
    "138": "trà vinh",
    "139": "tuyên quang",
    "140": "vĩnh long",
    "141": "vĩnh phúc",
    "142": "yên bái",
    "143": "cầu giấy",
    "144": "kim mã",
    "145": "vịnh hạ long",
    "146": "xin",
    "147": "chào",
    "148": "châu",
    "149": "cho tôi 1",
    "150": "lúc",
    "151": "nào",
    "152": "anh",
    "153": "chị",
    "154": "vào",
    "155": "ạ"
}

# MARK: FUZZY
def remove_accents(text):

    text = unicodedata.normalize("NFD", text)

    text = "".join(
        c
        for c in text
        if unicodedata.category(c) != "Mn"
    )

    return text.replace("đ", "d").replace("Đ", "D").lower()

def clean_all(text):

    return remove_accents(text).replace(" ", "").lower()

def normalize_text(text):

    return " ".join(text.strip().lower().split())


def load_dictionary():

    if not os.path.exists(DICT_FILE):

        raise FileNotFoundError(f"Không tìm thấy {DICT_FILE}")

    with open(DICT_FILE, "r", encoding="utf-8") as f:

        data = json.load(f)

    tokenizer_dict = {
        int(k): normalize_text(v)
        for k, v in data.items()
    }

    return tokenizer_dict

def build_dict_index(tokenizer_dict):

    index = []

    for token_id, token_value in tokenizer_dict.items():

        if token_id in (PAD_ID, UNK_ID):
            continue

        if token_value in ("<pad>", "<unk>"):
            continue

        if not token_value:
            continue

        word_count = len(token_value.split())

        index.append((token_id, token_value, word_count))

    return index

def calculate_vietnamese_similarity(w1_normalized, w2_normalized):

    w1_clean = w1_normalized
    w2_clean = w2_normalized

    if w1_clean == w2_clean:
        return 1.0

    w1_no = remove_accents(w1_clean)
    w2_no = remove_accents(w2_clean)

    if w1_no == w2_no:
        return 0.95

    if len(w1_no) <= 3 or len(w2_no) <= 3:

        if not w1_no or not w2_no:
            return 0.0

        if w1_no[0] != w2_no[0]:
            return 0.0

    w1_all = w1_no.replace(" ", "")
    w2_all = w2_no.replace(" ", "")

    score_all = SequenceMatcher(None, w1_all, w2_all).ratio()
    score_acc = SequenceMatcher(None, w1_clean, w2_clean).ratio()

    return max(score_all, score_acc)

def find_best_match(
    text,
    dict_index,
    threshold=0.75,
    must_be_phrase=False
):

    input_text = normalize_text(text)
    input_word_count = len(input_text.split())

    best_id = None
    best_word = None
    highest_score = 0.0

    for token_id, token_value, dict_word_count in dict_index:

        if must_be_phrase:

            if input_word_count < 2:
                continue

            if dict_word_count != input_word_count:
                continue

        score = calculate_vietnamese_similarity(
            input_text,
            token_value
        )

        if score > highest_score:

            highest_score = score
            best_id = token_id
            best_word = token_value

    if highest_score >= threshold and best_id is not None:

        return best_id, best_word, highest_score

    return None, None, 0.0

def decode(
    token_ids,
    tokenizer_dict,
    compress_duplicates=False,
    show_unk=True
):

    if not token_ids:
        return ""

    if compress_duplicates:
        token_ids = compress_sequence(token_ids)

    transcriptions = []

    for token_id in token_ids:

        if token_id == PAD_ID:
            continue

        if token_id == UNK_ID:

            if show_unk:
                transcriptions.append(UNK_MARKER)

            continue

        token = tokenizer_dict.get(token_id)

        if token is None:
            continue

        if token in ("<pad>", "<unk>"):
            continue

        if token:
            transcriptions.append(token)

    return " ".join(transcriptions)

AMBIGUOUS_SINGLE_WORDS = {"không", "năm"}

def vietnamese_number_to_digit(text):

    text = text.lower().strip()

    number_map = {
        "không": 0,
        "một": 1,
        "hai": 2,
        "ba": 3,
        "bốn": 4,
        "năm": 5,
        "sáu": 6,
        "bảy": 7,
        "tám": 8,
        "chín": 9
    }

    is_single_word = " " not in text

    if is_single_word and text in AMBIGUOUS_SINGLE_WORDS:
        return None

    if text in number_map:
        return str(number_map[text])

    if text == "mười":
        return "10"

    if text.startswith("mười "):

        unit = text.replace("mười ", "").strip()

        if unit == "lăm":
            return "15"

        if unit in number_map:
            return str(10 + number_map[unit])

    for tens_word, tens_value in {
        "hai": 20,
        "ba": 30,
        "bốn": 40,
        "năm": 50,
        "sáu": 60,
        "bảy": 70,
        "tám": 80,
        "chín": 90
    }.items():

        if text == f"{tens_word} mươi":
            return str(tens_value)

        if text.startswith(f"{tens_word} mươi "):

            unit = text.replace(f"{tens_word} mươi ", "").strip()

            if unit == "lăm":
                return str(tens_value + 5)

            if unit == "mốt":
                return str(tens_value + 1)

            if unit in number_map:
                return str(tens_value + number_map[unit])

    if text == "một trăm":
        return "100"

    return None

def process_text_semantic(
    input_text,
    tokenizer_dict,
    max_phrase_length=4,
    phrase_threshold=0.75,
    word_threshold=0.78,
    add_unknown=False
):
    input_text = normalize_text(input_text)

    if not input_text:
        return [], ""

    words = input_text.split()

    dict_index = build_dict_index(tokenizer_dict)

    token_ids = []

    i = 0
    n = len(words)

    while i < n:

        matched = False

        for number_window in range(min(3, n - i), 0, -1):

            number_text = " ".join(words[i:i + number_window])

            number_result = vietnamese_number_to_digit(number_text)

            if number_result is not None:

                match_id, match_word, score = find_best_match(
                    text=number_result,
                    dict_index=dict_index,
                    threshold=word_threshold,
                    must_be_phrase=False
                )

                if match_id is not None:

                    print(
                        f"[CHUYỂN SỐ] "
                        f"'{number_text}' "
                        f"-> '{number_result}' "
                        f"-> ID {match_id}"
                    )

                    token_ids.append(match_id)

                    i += number_window

                    matched = True

                    break

        if matched:
            continue

        max_window = min(max_phrase_length, n - i)

        for window in range(max_window, 1, -1):

            ngram_raw = " ".join(words[i:i + window])

            match_id, match_word, score = find_best_match(
                text=ngram_raw,
                dict_index=dict_index,
                threshold=phrase_threshold,
                must_be_phrase=True
            )

            if match_id is not None:

                print(
                    f"[KHỚP CỤM] "
                    f"'{ngram_raw}' "
                    f"-> '{match_word}' "
                    f"(ID: {match_id}) "
                    f"[{score * 100:.1f}%]"
                )

                token_ids.append(match_id)

                i += window

                matched = True

                break

        if matched:
            continue

        single_word = words[i]

        match_id, match_word, score = find_best_match(
            text=single_word,
            dict_index=dict_index,
            threshold=word_threshold,
            must_be_phrase=False
        )

        if match_id is not None:

            if single_word != match_word:

                print(
                    f"[SỬA / KHỚP] "
                    f"'{single_word}' "
                    f"-> '{match_word}' "
                    f"(ID: {match_id}) "
                    f"[{score * 100:.1f}%]"
                )

            else:

                print(f"[KHỚP] '{single_word}' -> ID {match_id}")

            token_ids.append(match_id)

        else:

            if add_unknown:

                print(
                    f"[KHÔNG TÌM THẤY] "
                    f"'{single_word}' "
                    f"-> <unk> "
                    f"(ID: {UNK_ID})"
                )

                token_ids.append(UNK_ID)

        i += 1

    normalized_text = decode(
        token_ids=token_ids,
        tokenizer_dict=tokenizer_dict,
        compress_duplicates=False,
        show_unk=True
    )
    return normalized_text

def fuzzy_main():

    print("\nText nhận dạng từ WAV2VEC2:")
    user_input = "cho tôi môt xe đến kin mã từ ha phòng"

    output_text = process_text_semantic(
        input_text=user_input,
        tokenizer_dict=fuzyy_tokenizer_dict,
        max_phrase_length=4,
        phrase_threshold=0.75,
        word_threshold=0.78,
        add_unknown=False
    )

    print(f"Decoded text: {output_text}")


if __name__ == "__main__":
    fuzzy_main()