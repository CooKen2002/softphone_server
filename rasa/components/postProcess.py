from __future__ import annotations

from typing import Any, Dict, List, Optional, Text

from rasa.engine.graph import ExecutionContext, GraphComponent
from rasa.engine.recipes.default_recipe import DefaultV1Recipe
from rasa.engine.storage.resource import Resource
from rasa.engine.storage.storage import ModelStorage
from rasa.shared.nlu.training_data.message import Message
from rasa.shared.nlu.training_data.training_data import TrainingData


@DefaultV1Recipe.register(
    component_types=DefaultV1Recipe.ComponentType.ENTITY_EXTRACTOR,
    is_trainable=False,
)
class PostProcess(GraphComponent):

    # -------------------------------------------------------------------
    # MARK:CONFIG
    # -------------------------------------------------------------------

    @classmethod
    def get_default_config(cls) -> Dict[Text, Any]:
        return {
            "min_intent_confidence": 0.9,
            "min_entity_confidence": 0.5,
            "min_merging_confidence": 0.2,
        }

    @classmethod
    def create(
        cls,
        config: Dict[Text, Any],
        model_storage: ModelStorage,
        resource: Resource,
        execution_context: ExecutionContext,
    ) -> PostProcess:
        return cls(config)

    def __init__(self, config: Dict[Text, Any]) -> None:
        self.min_entity_confidence: float = config.get("min_entity_confidence")
        self.min_intent_confidence: float = config.get("min_intent_confidence")
        self.min_merging_confidence: float = config.get("min_merging_confidence")

    # ------------------------------------------------------------------
    # MARK:PROCESS
    # ------------------------------------------------------------------

    def process(self, messages: List[Message]) -> List[Message]:
        for message in messages:
            # In ra intent ranking nếu intent của text < min_intent_confidence
            self.checking_intent(message)
            # Lọc các entities confidence < min_entity_confidence
            self.clear_entities(message)
            # Gộp các entity bị tách trước bỏ qua các entity < min_merging_confidence
            self.merge_adjacent_entities(message)
        return messages

    # ------------------------------------------------------------------
    # MARK:LOGIC
    # ------------------------------------------------------------------

    def clear_entities(self, message: Message) -> None:
        entities = message.get("entities", [])
        # LOG: CHECK MẢNG ENTITIES TRƯỚC KHI CLEAR
        print(f'\n first entity:\n {entities}\n')
        clean_entities = []
        for entity in entities:
            if entity.get("confidence_entity") < self.min_entity_confidence:
                print(f"Low confidence entity detected: {entity}")
                continue
            if entity.get("entity") == "dien_thoai":
                if len(entity.get("value")) < 10:
                    print(f"dien_thoai detected: {entity}")
                    continue
            clean_entities.append(entity)

        message.set("entities", clean_entities, add_to_output=True)

    def checking_intent(self, message: Message) -> Optional[Text]:
        intent_ranking = message.get("intent_ranking", [])
        if intent_ranking[0].get("confidence", 0) < self.min_intent_confidence:
            print(
                f"Intent ranking:\n",
                f"{intent_ranking[0]} - conf : {intent_ranking[0].get('confidence', 0):.2f}\n",
                f"{intent_ranking[1]} - conf : {intent_ranking[1].get('confidence', 0):.2f}\n",
                f"{intent_ranking[2]} - conf : {intent_ranking[2].get('confidence', 0):.2f}\n",
                f"{intent_ranking[3]} - conf : {intent_ranking[3].get('confidence', 0):.2f}\n",
                f"{intent_ranking[4]} - conf : {intent_ranking[4].get('confidence', 0):.2f}\n",
            )

    def merge_adjacent_entities(self, message: Message) -> None:
        entities = message.get("entities", [])
        # LOG: CHECK MẢNG ENTITIES TRƯỚC KHI MERGE
        print(f'\n after clear entity:\n {entities}\n ')
        if not entities or len(entities) < 2:
            return

        entities.sort(key=lambda x: x["start"])
        new_entities = []
        # Bắt đầu với phần tử đầu tiên
        current = entities[0].copy()

        for i in range(1, len(entities)):
            if current["entity"] == "dia_diem":
                new_entities.append(current)
                current = entities[i]
                continue
            next_ent = entities[i]
            # Kiểm tra khoảng cách và cùng loại
            # Cho phép khoảng cách tối đa 1 (space)
            if (
                current["entity"] == next_ent["entity"]
                and (next_ent["start"] - current["end"]) <= 1
                and float(next_ent["confidence_entity"]) > self.min_merging_confidence
            ):

                print(f"\n Merging entities: {current} + {next_ent}\n")
                # Cập nhật end và value của current (gộp tiếp vào)
                current["end"] = next_ent["end"]
                current["value"] = message.get("text")[
                    current["start"] : current["end"]
                ]
                # Lấy confidence trung bình hoặc min
                current["confidence_entity"] = min(
                    current.get("confidence_entity"), next_ent.get("confidence_entity")
                )
            else:
                # Nếu không gộp được nữa, lưu lại phần tử đã hoàn thiện
                new_entities.append(current)
                current = next_ent.copy()

        # Đừng quên thêm phần tử cuối cùng
        new_entities.append(current)

        message.set("entities", new_entities, add_to_output=True)
