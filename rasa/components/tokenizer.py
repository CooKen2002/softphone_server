from typing import List, Text

from rasa.engine.recipes.default_recipe import DefaultV1Recipe

from rasa.nlu.tokenizers.whitespace_tokenizer import WhitespaceTokenizer
from rasa.nlu.tokenizers.tokenizer import Token

from rasa.shared.nlu.training_data.message import Message

@DefaultV1Recipe.register(
    DefaultV1Recipe.ComponentType.MESSAGE_TOKENIZER, is_trainable=False
)
class SKS_Tokenizer(WhitespaceTokenizer):

    def tokenize(self, message: Message, attribute: Text) -> List[Token]:
        original_text = message.get(attribute)
        if not original_text:
            return []

        # Normalize
        normalized_text = normalize_text(original_text)
        print(f"[Tokenizer] : original_text: {original_text}")
        print(f"[Tokenizer] : normalized_text: {normalized_text}")

        message.set(attribute, normalized_text)

        # Gọi tokenizer gốc
        tokens = super().tokenize(message, attribute)

        # Thêm metadata vào tokens
        # for token in tokens:
        #     annotate_text(token)
        #     print(f"[Tokenizer] : text: {token.text}, data: {token.data}")

        return tokens


import re


def normalize_text(text: str):

    text = text.lower()

    # chuẩn hóa khoảng trắng
    text = re.sub(r"\s+", " ", text)

    # chuẩn hóa về số đếm
    text = text_to_number(text)

    # chuẩn hóa thời gian
    text = re.sub(r"(\d{1,2})\s*giờ\s*(\d{1,2})", r"\1h\2", text)  # 10 giờ 30 -> 10h30
    text = re.sub(r"(\d{1,2})\s*giờ", r"\1h", text)  # 10 giờ -> 10h

    # chuẩn hóa số điện thoại
    text = re.sub(
        r"(\d{4})\s+(\d{3})\s+(\d{3})", r"\1\2\3", text
    )  # 0909 123 456 -> 0909123456
    text = re.sub(
        r"(\d{4})-(\d{3})-(\d{3})", r"\1\2\3", text
    )  # 0909-123-456 -> 0909123456

    return text.strip()


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
    pattern = r"\b(?:(?:một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+(?:nghìn|ngàn)(?:\s+(?:không|một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+trăm)?(?:\s+(?:linh|lẻ|(?:hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+mươi|mười))?(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|tám|chín))?|(?:không|một|hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+trăm(?:\s+(?:linh|lẻ|(?:hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+mươi|mười))?(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|tám|chín))?|(?:không\s+không|một\s+một|hai\s+hai|ba\s+ba|bốn\s+bốn|tư\s+tư|năm\s+năm|sáu\s+sáu|bảy\s+bảy|tám\s+tám|chín\s+chín)|(?:hai|ba|bốn|năm|sáu|bảy|tám|chín)\s+mươi(?:\s+(?:một|tư|hai|ba|bốn|lăm|năm|sáu|bảy|tám|chín))?|mười\s+(?:một|hai|ba|bốn|lăm|năm|sáu|bảy|tám|chín)|không|một|hai|ba|bốn|tư|năm|sáu|bảy|tám|chín|mười)\b"

    return re.sub(pattern, lambda x: parse_chunk(x.group(0)), text, flags=re.IGNORECASE)


def annotate_text(token):
    # PHONE
    if re.fullmatch(r"0\d{9}", token.text):
        token.data["entity_types"] = ["dien_thoai"]

    # TIME
    if re.fullmatch(r"\d{1,2}h\d{0,2}", token.text):
        token.data["entity_types"] = ["thoi_gian"]


"""
Ví dụ dùng 1 chức năng mới
class CustomTokenizer(Tokenizer, GraphComponent):

    def __init__(self, config):
        super().__init__(config)

    @classmethod
    def create(
        cls,
        config,
        model_storage,
        resource,
        execution_context
    ):
        return cls(config)

    def tokenize(self, message: Message, attribute: Text) -> List[Token]:

        text = message.get(attribute)

        if not text:
            return []

        words = re.findall(r'\d+|[^\W\d_]+', text)

        tokens = []

        running_offset = 0

        for word in words:

            start = text.find(word, running_offset)

            tokens.append(
                Token(
                    text=word,
                    start=start
                )
            )

            running_offset = start + len(word)

        return tokens
"""
