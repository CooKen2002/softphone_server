import re
import numpy as np
from typing import Any, Text, Dict, List, Type

from rasa.engine.recipes.default_recipe import DefaultV1Recipe

from rasa.nlu.featurizers.sparse_featurizer.lexical_syntactic_featurizer import (
    LexicalSyntacticFeaturizer
)

from rasa.shared.nlu.training_data.message import Message
from rasa.shared.nlu.constants import TEXT
from rasa.nlu.constants import TOKENS_NAMES

@DefaultV1Recipe.register(
    DefaultV1Recipe.ComponentType.MESSAGE_FEATURIZER,
    is_trainable=False
)

class SKS_LexicalSyntacticFeaturizer(LexicalSyntacticFeaturizer):

    def _map_tokens_to_raw_features(self, tokens):

        sentence_features = super()._map_tokens_to_raw_features(
            tokens
        )

        # self.print_raw_features(
        #     tokens,
        #     sentence_features
        # )

        return sentence_features

    def print_raw_features(
        self,
        tokens,
        sentence_features
    ):

        # =====================================
        # LẤY TOÀN BỘ FEATURE NAMES
        # =====================================
        feature_names = set()

        for feats in sentence_features:

            for k in feats.keys():
                feature_names.add(k)

        feature_names = sorted(
            list(feature_names)
        )

        # =====================================
        # HEADER
        # =====================================
        header = f"{'TOKEN':<20}"

        for name in feature_names:
            header += f"{str(name):<25}"

        print("\n")
        print(header)

        print("-" * len(header))

        # =====================================
        # ROWS
        # =====================================
        for token, feats in zip(
            tokens,
            sentence_features
        ):

            line = f"{token.text:<20}"

            for name in feature_names:

                value = feats.get(name, "")

                line += f"{str(value):<25}"

            print(line)

        print("\n")