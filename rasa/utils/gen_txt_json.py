import json
from typing import Any, Dict, List, Text
from pathlib import Path
import random
from load import *

# =========================
# PATH
# =========================
UTILS_PATH = r"./utils/examples"
SKS_TOKEN_PATH = r"./components/sks_tokenizer"
# =========================
# MARK: PLACEHOLDER
# =========================
placeholder2Entity = {
    "__DIADIEM__": "dia_diem",
    "__THOIGIAN__": "thoi_gian",
    "__LOAIXE__": "loai_xe",
    "__SOLUONG__": "so_luong",
    "__HOTEN__": "ho_ten",
    "__DIENTHOAI__": "dien_thoai",
}


def sort_long_to_short(words: List = None):
    return sorted(words, key=lambda x: (-len(x), x))


def generate_dia_diem(
    path: str = rf"{UTILS_PATH}/dia_diem.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        f"{UTILS_PATH}/{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_thoi_gian(
    path: str = r"{UTILS_PATH}\thoi_gian.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{UTILS_PATH}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_so_luong(
    path: str = r"UTILS_PATH\so_luong.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{UTILS_PATH}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_loai_xe(
    path: str = r"UTILS_PATH\\loai_xe.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{UTILS_PATH}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_ho_ten(
    path: str = r"UTILS_PATH\\ho_ten.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{UTILS_PATH}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_dien_thoai(
    path: str = r"UTILS_PATH\\dien_thoai.txt",
):
    file = Path(path)
    name = file.name.split(".")[0]
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{UTILS_PATH}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_entity(path: str):
    file = Path(path)
    name = file.name.split(".")[0]
    root = file.parent
    phrases = load_phrases(file)
    phrases_sort = sort_long_to_short(phrases)
    entity = {name: phrases_sort}
    with open(
        rf"{root}\{name}.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entity, f, ensure_ascii=False, indent=4)

    return entity


def generate_entity_json(pathRoot: str, path_entity: List[str] = []):
    if len(path_entity) == 0:
        print("Không có file nào được truyền vào")
        return

    # Folder root
    folder = Path(pathRoot)
    if not folder:
        folder.mkdir()
    entities = {}
    for path in path_entity:
        entity = generate_entity(path=path)
        entities.update(entity)

    with open(
        rf"{folder}\entities.json",
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(entities, f, ensure_ascii=False, indent=4)

    return rf"{folder}\entities.json"


def generate_phrases(
    path_phrases: str = rf"{SKS_TOKEN_PATH}\phrases.txt",  # lưu vào component của sks token
    path_entity: str = None,
    path_intent: str = None,
    path_word: str = None,
):
    if not path_entity or len(path_entity.strip()) == 0:
        return

    file_entity = Path(path_entity)
    entity_json = load_json(file_entity)

    # Chỉ load nếu đường dẫn không phải None và tồn tại
    # Sort cả intents và words theo độ dài giảm dần để tránh đếm thiếu index khi có nhiều từ trùng nhau
    intent_list = sort_long_to_short(load_txt(Path(path_intent))) if path_intent else []
    word_list = sort_long_to_short(load_txt(Path(path_word))) if path_word else []

    with open(path_phrases, mode="w", encoding="utf-8") as f:
        # Ghi intents
        for intent in intent_list:
            f.write(f"{intent}\n")

        f.write(f"\n")
        # Ghi words
        for word in word_list:
            f.write(f"{word}\n")

        # Ghi entities
        for entity_type, values in entity_json.items():
            f.write(f"\n# {entity_type}\n")
            for value in values:
                f.write(f"{value.lower()}\n")


def generate_nlu(
    file_name: str = None,
    list_json: Dict = None,
    pattern: str = None,
    intent: str = None,
):
    data_nlu = f'version: "3.1"\nnlu:\n- intent: {intent}\n  examples: |\n'
    for pt in pattern:
        for item in list_json:
            text = pt
            for key, values in item.items():
                if key == "__DIADIEM__":
                    for dia_diem in values:
                        text = text.replace(key, dia_diem.lower(), 1)
                        text = text.replace(f"E{key}", placeholder2Entity[key], 1)
                    continue
                text = text.replace(key, values.lower(), 1)
                text = text.replace(f"E{key}", placeholder2Entity[key], 1)
            data_nlu += f"    {text}\n"

    with open(file_name, "w", encoding="utf-8") as f:
        f.write(data_nlu)


def gen_list_json(number: int):
    entities = load_json(Path(f"{UTILS_PATH}\\entities.json"))
    final_list = []

    for i in range(number):
        dia_diem_ngau_nhien = random.sample(entities["dia_diem"], 2)

        thoi_gian_ngau_nhien = random.choice(entities["thoi_gian"])
        dien_thoai_ngau_nhien = random.choice(entities["dien_thoai"])
        ho_ten_ngau_nhien = random.choice(entities["ho_ten"])
        loai_xe_ngau_nhien = random.choice(entities["loai_xe"])
        so_luong_ngau_nhien = random.choice(entities["so_luong"])

        final_list.append(
            {
                "__DIADIEM__": dia_diem_ngau_nhien,
                "__THOIGIAN__": thoi_gian_ngau_nhien,
                "__LOAIXE__": loai_xe_ngau_nhien,
                "__SOLUONG__": so_luong_ngau_nhien,
                "__HOTEN__": ho_ten_ngau_nhien,
                "__DIENTHOAI__": dien_thoai_ngau_nhien,
            }
        )

    return final_list


# MARK: MAIN
generate_dia_diem()
generate_ho_ten()
# generate_so_luong()
# generate_thoi_gian()
# generate_dien_thoai()
# generate_loai_xe()


file_json = generate_entity_json(
    pathRoot=SKS_TOKEN_PATH,
    path_entity=[
        rf"{UTILS_PATH}\dia_diem.txt",
        rf"{UTILS_PATH}\ho_ten.txt",
        # fr"{UTILS_PATH}\dien_thoai.txt",
        # fr"{UTILS_PATH}\loai_xe.txt",
        # fr"{UTILS_PATH}\thoi_gian.txt",
        # fr"{UTILS_PATH}\so_luong.txt",
    ],
)

generate_phrases(
    path_entity=file_json,
    path_intent=rf"{UTILS_PATH}\intent.txt",
    path_word=rf"{UTILS_PATH}\word.txt",
)
