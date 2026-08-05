from rasa.engine.recipes.default_recipe import DefaultV1Recipe
from typing import Any, Text, Dict, List, Type
from rasa.nlu.featurizers.sparse_featurizer.count_vectors_featurizer import (
    CountVectorsFeaturizer,
)

from rasa.shared.nlu.training_data.message import Message
from rasa.shared.nlu.constants import TEXT


@DefaultV1Recipe.register(
    DefaultV1Recipe.ComponentType.MESSAGE_FEATURIZER, is_trainable=True
)
class SKS_CountVectorsFeaturizer(CountVectorsFeaturizer):

    def _get_message_text_by_attribute(self, message, attribute):

        text = super()._get_message_text_by_attribute(message, attribute)

        # ==================================
        # CUSTOM NORMALIZE
        # ==================================
        text = text.lower()

        # normalize phone
        text = text.replace("+84", "0")

        return text

    def process(self, messages: List[Message]) -> List[Message]:

        messages = super().process(messages)

        # self.debug_features(messages)

        return messages

    def debug_features(self, messages):

        print("\n" + "=" * 80)

        print("COUNT VECTOR FEATURES")

        for message in messages:

            print("\nTEXT:")
            print(message.get(TEXT))

            for feature in message.features:
                if "SKS_CountVectorsFeaturizer" in feature.origin:
                    print("\nFEATURE:")
                    print("origin:", feature.origin)
                    print("type:", feature.type)
                    print("attribute:", feature.attribute)
                    print("shape:", feature.features.shape)

                    matrix = feature.features.toarray()
                    # print(self.vectorizers[TEXT].vocabulary_)
                    print(self.vectorizers[TEXT].get_feature_names_out())
                    print(matrix)

        print("\n" + "=" * 80)
