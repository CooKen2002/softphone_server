import re
import numpy as np
from typing import Any, Text, Dict, List, Type

from rasa.engine.recipes.default_recipe import DefaultV1Recipe

from rasa.nlu.featurizers.sparse_featurizer.regex_featurizer import RegexFeaturizer

from rasa.shared.nlu.training_data.message import Message
from rasa.shared.nlu.constants import TEXT
from rasa.nlu.constants import TOKENS_NAMES

@DefaultV1Recipe.register(
    DefaultV1Recipe.ComponentType.MESSAGE_FEATURIZER, is_trainable=True
)
class SKS_RegexFeaturizer(RegexFeaturizer):

    def process(self, messages: List[Message]) -> List[Message]:

        messages = super().process(messages)
        
        # for message in messages:
        #     text = message.get("text")
            
        #     print("\n" + "=" * 60)
        #     print("TEXT:", text)
            
        #     tokens = message.get(TOKENS_NAMES[TEXT])
        #     token_texts = [token.text for token in tokens]
        #     for t in token_texts:
        #         if re.search(r"\b(\+84|0)\d{9,10}\b", t):
        #             print(t)

        #     regex_names = [pattern["name"] for pattern in self.known_patterns]
        #     print(regex_names)
            
        #     for feature in message.features:
        #         print("\nFEATURE:")
        #         print("origin:", feature.origin)
        #         print("type:", feature.type)
        #         print("attribute:", feature.attribute)
        #         print("shape:", feature.features.shape)
        #         matrix = feature.features.toarray()

        #         # =========================
        #         # HEADER
        #         # =========================
        #         header = f"{'TOKEN':<20}"

        #         for regex_name in regex_names:
        #             header += f"{regex_name.upper():<20}"

        #         print(header)

        #         print("-" * len(header))

        #         # =========================
        #         # ROWS
        #         # =========================
        #         for token, row in zip(token_texts, matrix):

        #             line = f"{token:<20}"

        #             for value in row:
        #                 line += f"{value:<20}"

        #             print(line)
        #     print("\n")
        return messages
