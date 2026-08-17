import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, List, Text

from rasa.engine.graph import GraphComponent
from rasa.engine.recipes.default_recipe import DefaultV1Recipe
from rasa.shared.nlu.training_data.message import Message
from rasa.shared.nlu.training_data.training_data import TrainingData
from rasa.nlu.tokenizers.tokenizer import Token, Tokenizer
from rasa.shared.nlu.constants import TEXT
from rasa.nlu.constants import TOKENS_NAMES

from utils.utils import *
from utils.load import *


@DefaultV1Recipe.register(
    DefaultV1Recipe.ComponentType.MESSAGE_TOKENIZER, is_trainable=False
)
class SKS_tokenizer(Tokenizer, GraphComponent):

    @staticmethod
    def get_default_config():
        return {"intent_tokenization_flag": False, "intent_split_symbol": "_"}

    def __init__(self, config: Dict[Text, Any]):
        super().__init__(config)

        base_path = Path(config.get("base_path", "."))

        self.aliases = load_json(base_path / "aliases.json")

        self.entities = load_json(base_path / "entities.json")

        self.phrases = load_phrases(base_path / "phrases.txt")

        self.placeholder = load_json(base_path / "placeholder.json")

        self.trie = PhraseTrie()
        entity_type = None
        for phrase in self.phrases:
            if phrase.startswith("#"):
                entity_type = phrase[1:].strip()
                continue
            self.trie.insert(phrase, entity_type)

        self.base_path = base_path
        self.dynamic_phrases = set()

    # =========================
    # Dynamic Phrase Mining
    # =========================

    def mine_phrases(self, training_data: TrainingData):
        for example in training_data.training_examples:
            for entity in example.get("entities", []):
                value = entity["value"]
                entity_type = entity["entity"]
                if len(value.split()) > 1:
                    self.trie.insert(value.lower(), entity_type)

    # =========================
    # Entity-aware Phrase Insert
    # =========================

    def add_entity_phrases(self):
        for entity_type, values in self.entities.items():
            for value in values:
                self.trie.insert(value.lower(), entity_type)

    # =========================
    # Tokenize
    # =========================

    def custom_tokenize(self, text: str):
        original_text = text
        words = text.split()
        tokens = []
        i = 0
        while i < len(words):
            longest_end, entity_type = self.trie.longest_match(words, i)
            if longest_end != -1:
                phrase_words = words[i : longest_end + 1]
                merged = "_".join(phrase_words)
                tokens.append({TEXT: merged, "entity_type": entity_type})
                i = longest_end + 1
            else:
                # Không tìm thấy trong entities)
                tokens.append({TEXT: words[i], "entity_type": entity_type})
                i += 1
        return tokens

    # =========================
    # Rasa tokenize()
    # =========================
    def tokenize(self, message: Message, attribute: Text) -> List[Token]:
        text = message.get(attribute)
        self.phrases = load_phrases(self.base_path / "phrases_runtime.txt")
        entity_type = None
        for phrase in self.phrases:
            if phrase.startswith("#"):
                entity_type = phrase[1:].strip()
                continue
            self.trie.insert(phrase, entity_type)

        normalized_text = normalize_text(text)
        # Thêm marker vào entity với trường hợp không có entity_type
        normalized_text_marker = mark_entities(normalized_text)
        token_strings = self.custom_tokenize(normalized_text_marker)

        tokens = []
        running_offset = 0
        message.set(attribute, normalized_text)

        for token_text in token_strings:
            search_text = token_text.get(TEXT).replace("_", " ")
            entity_type = token_text.get("entity_type")
            placehold = None

            if "A" in search_text:
                entity_type = "so_luong"
                search_text = search_text[2:]
            elif "P" in search_text:
                entity_type = "dien_thoai"
                search_text = search_text[2:]
            elif any(char in search_text for char in ["I", "D", "T"]):
                entity_type = "thoi_gian"
                search_text = search_text[2:].strip()

            start = normalized_text.find(search_text, running_offset)

            if start == -1:
                start = running_offset
            end = start + len(search_text)
            running_offset = end

            if entity_type:
                placehold = self.placeholder.get(entity_type)
            else:
                # xử lý các entity còn lại
                placehold = search_text

            token = Token(
                text=placehold,
                start=start,
                end=end,
                data={"entity_type": entity_type, "text": search_text},
            )

            tokens.append(token)

        print("\nTOKENIZE:")
        print("=" * 60)
        print(f"{'Token':<20}{'start':<20}{'end':<20}{'text':<20}")
        for t in tokens:
            line = f"{t.text:<20}{t.start:<20}{t.end:<20}{t.data['text']:<20}"
            print(line)

        return tokens

    # =========================
    # Train
    # =========================

    def train(self, training_data: TrainingData):

        self.mine_phrases(training_data)

        self.add_entity_phrases()

        return self

    # =========================
    # Process
    # =========================

    def process(self, messages: List[Message]) -> List[Message]:

        for message in messages:
            tokens = self.tokenize(message, attribute=TEXT)
            message.set(TOKENS_NAMES[TEXT], tokens)

        return messages

    # =========================
    # Required
    # =========================

    @classmethod
    def create(cls, config, model_storage, resource, execution_context):
        config = {**cls.get_default_config(), **config}
        return cls(config)
