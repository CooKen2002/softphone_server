import os
import tarfile
import shutil
import tempfile
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
import requests

MODEL_PATH = "models"
RASA_URL = "http://localhost:5005"

def extract_tar(tar_path, extract_dir):
    with tarfile.open(tar_path, "r:gz") as tar:
        tar.extractall(extract_dir)


def create_tar(source_dir, output_tar):
    with tarfile.open(output_tar, "w:gz") as tar:
        for item in os.listdir(source_dir):
            tar.add(os.path.join(source_dir, item), arcname=item)


def find_model_root(path):
    """
    Tìm thư mục chứa metadata.json
    """

    for root, dirs, files in os.walk(path):
        if "metadata.json" in files:
            return root

    raise Exception("Không tìm thấy metadata.json")


def merge_model(full_model_tar, nlu_model_tar, output_tar):

    workdir = tempfile.mkdtemp()

    try:

        full_dir = os.path.join(workdir, "full")
        nlu_dir = os.path.join(workdir, "nlu")

        os.makedirs(full_dir)
        os.makedirs(nlu_dir)

        print("Extract full model...")
        extract_tar(full_model_tar, full_dir)

        print("Extract nlu model...")
        extract_tar(nlu_model_tar, nlu_dir)

        full_root = find_model_root(full_dir)
        nlu_root = find_model_root(nlu_dir)

        full_nlu = os.path.join(full_root, "components")
        new_nlu = os.path.join(nlu_root, "components")

        if not os.path.exists(new_nlu):
            raise Exception("Không tìm thấy thư mục nlu trong model NLU")

        print("Replace NLU...")

        if os.path.exists(full_nlu):
            shutil.rmtree(full_nlu)

        shutil.copytree(new_nlu, full_nlu)

        print("Create combined model...")
        create_tar(full_root, output_tar)

        print(f"Done: {output_tar}")

    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def merge_model_new(core_model_tar, nlu_model_tar, output_tar):
    print(f"Start Merge: {core_model_tar} + {nlu_model_tar}")
    workdir = tempfile.mkdtemp()
    try:
        print("Create temp file")
        # Tạo folder tạm
        core_dir = os.path.join(workdir, "core")
        nlu_dir = os.path.join(workdir, "nlu")
        os.makedirs(core_dir)
        os.makedirs(nlu_dir)

        # Giải nén model
        print(f"Extracting: {core_model_tar}")
        extract_tar(core_model_tar, core_dir)

        print(f"Extracting: {nlu_model_tar}")
        extract_tar(nlu_model_tar, nlu_dir)

        core_root = find_model_root(core_dir)
        nlu_root = find_model_root(nlu_dir)

        new_core = os.path.join(core_root, "components")
        new_nlu = os.path.join(nlu_root, "components")

        if not os.path.exists(new_nlu):
            raise Exception("Không tìm thấy thư mục components trong model NLU")
        if not os.path.exists(new_core):
            raise Exception("Không tìm thấy thư mục components trong CORE")

        print("Copy Componens")
        shutil.copytree(
            new_nlu,
            new_core,
            ignore=shutil.ignore_patterns("finetuning_validator"),
            dirs_exist_ok=True,
        )  # finetuning_validator

        print("Update metadata.json")
        # Cập nhật metadata.json
        with open(f"{core_root}/metadata.json", encoding="utf8") as f:
            core = json.load(f)

        with open(f"{nlu_root}/metadata.json", encoding="utf8") as f:
            nlu = json.load(f)

        # "train_chema.nodes"
        for key in nlu["train_schema"]["nodes"].keys():
            if "schema_validator" == key:
                continue
            if "finetuning_validator" == key:
                # "train_schema.finetuning_validator.config": {"validate_core": true, "validate_nlu": true}
                core["train_schema"]["nodes"][key]["config"].update(
                    {"validate_core": True, "validate_nlu": True}
                )
                continue
            core["train_schema"]["nodes"][key] = nlu["train_schema"]["nodes"][key]

        # "predict_schema.nodes"
        for key in nlu["predict_schema"]["nodes"].keys():
            if "nlu_message_converter" == key:
                continue
            if "run_RegexMessageHandler" == key:
                # "predict_schema.nodes.run_RegexMessageHandler.need": {"messages": "run_ResponseSelector4", "domain": "domain_provider"}
                core["predict_schema"]["nodes"][key]["needs"].update(
                    {
                        "messages": f"{nlu['predict_schema']['nodes'][key]['needs']['messages']}",
                        "domain": "domain_provider",
                    }
                )
                continue
            core["predict_schema"]["nodes"][key] = nlu["predict_schema"]["nodes"][key]

        # {"training_type": 3}
        core["training_type"] = 3

        with open(f"{core_root}/metadata.json", "w", encoding="utf8") as f:
            json.dump(core, f, ensure_ascii=False, indent=4)

        print(f"Create {output_tar}")
        create_tar(core_root, output_tar)
        print(f"Done: {output_tar}")

    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def merge_model_latest(folder_root):
    print("Start merge model latest")
    latest_file_nlu = None
    latest_file_core = None
    latest_time_nlu = None
    latest_time_core = None
    print("Find model nlu, core latest")
    for file in Path(folder_root).glob("*.tar.gz"):
        try:
            if "nlu-" in file.stem:
                # file.stem của .tar.gz sẽ là "nlu-20260603091530.tar"
                timestamp = file.stem.replace("nlu-", "")
                timestamp = timestamp.replace(".tar", "")

                dt = datetime.strptime(timestamp, "%Y%m%d%H%M%S")

                if latest_time_nlu is None or dt > latest_time_nlu:
                    latest_time_nlu = dt
                    latest_file_nlu = file
            if "core-" in file.stem:
                # file.stem của .tar.gz sẽ là "nlu-20260603091530.tar"
                timestamp = file.stem.replace("core-", "")
                timestamp = timestamp.replace(".tar", "")

                dt = datetime.strptime(timestamp, "%Y%m%d%H%M%S")

                if latest_time_core is None or dt > latest_time_core:
                    latest_time_core = dt
                    latest_file_core = file
        except Exception:
            continue

    if not latest_file_nlu or not latest_file_core:
        raise Exception("Không tìm thấy 1 trong 2 model nlu hoặc core")

    print(f"Found model nlu: {latest_file_nlu}")
    print(f"Found model core: {latest_file_core}")

    latest_time = (
        latest_time_nlu if latest_time_nlu > latest_time_core else latest_time_core
    )

    path_model_full = (
        f"{folder_root}/full-{latest_time.strftime('%Y%m%d%H%M%S')}.tar.gz"
    )
    path_model_core = (
        f"{folder_root}/core-{latest_time_core.strftime('%Y%m%d%H%M%S')}.tar.gz"
    )
    path_model_nlu = (
        f"{folder_root}/nlu-{latest_time_nlu.strftime('%Y%m%d%H%M%S')}.tar.gz"
    )

    merge_model_new(
        core_model_tar=path_model_core,
        nlu_model_tar=path_model_nlu,
        output_tar=path_model_full,
    )

    return path_model_full


# r"C:/Users/CooKen/sks/rasa2.0/models"
def train_core(time_stamp, folder_root):
    model_name = f"core-{time_stamp}"
    subprocess.run(
        [
            sys.executable,
            "-m",
            "rasa",
            "train",
            "core",
            "--fixed-model-name",
            model_name,
            "--out",
            folder_root,
        ]
    )


def train_nlu(time_stamp, folder_root):
    model_name = f"nlu-{time_stamp}"
    subprocess.run(
        [
            sys.executable,
            "-m",
            "rasa",
            "train",
            "nlu",
            "--fixed-model-name",
            model_name,
            "--out",
            folder_root,
        ]
    )


def check_server(url):
    print("Check server rasa")
    try:
        response = requests.get(url, timeout=5)

        if response.status_code == 200:
            print("Server rasa OK")
            return True

        print(f"Server rasa: {response.status_code}")
        return False

    except Exception:
        print("Server rasa FAILURE")
        return False


def reload_model(model_path=None):
    if not check_server(f"{RASA_URL}/status") or not model_path:
        return False

    print("Start reload model")
    response = requests.put(
        f"{RASA_URL}/model", json={"model_file": model_path}, timeout=60
    )

    if response.status_code in (200, 204):
        print("Reload model thành công")
        return True

    print("Reload model thất bại")
    print(response.status_code)
    print(response.text)
    return False


def train_all(folder_root):
    folder_root = MODEL_PATH
    time_stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    train_nlu(time_stamp, folder_root)
    train_core(time_stamp, folder_root)
    path_model = f"{folder_root}/full-{time_stamp}.tar.gz"
    merge_model_new(
        core_model_tar=f"{folder_root}/core-{time_stamp}.tar.gz",
        nlu_model_tar=f"{folder_root}/nlu-{time_stamp}.tar.gz",
        output_tar=path_model,
    )
    return path_model


# MARK: main
if __name__ == "__main__":
    train_NLU_Only = True  # True / False
    train_CORE_Only = True    # True / False

    folder_root = MODEL_PATH
    time_stamp = datetime.now().strftime("%Y%m%d%H%M%S")

    if train_NLU_Only and train_CORE_Only:
        train_all(folder_root)
    elif train_NLU_Only:
        train_nlu(time_stamp, folder_root)
    elif train_CORE_Only:
        train_core(time_stamp, folder_root)

    path_mode = merge_model_latest(folder_root)
    reload_model(path_mode)

"""
Combine two model
1. Xử lý metadata.json
- Chung: "session_config", "version"
- Trong "domain" của core: 
    "intents"
    "entities"
    "slots"
    "forms"
    "responses"
    "actions"
-> Nên lấy metadata.json của core làm chuẩn.
B1: Đọc 2 file metadata.json
B2: Trong "train_schema.nodes" của core, thêm nội dung "train_chema.nodes" của nlu
B2.1: Trong "predict_schema.nodes" của core, thêm nội dung "predict_schema.nodes" của nlu
B3: Update của core: "train_schema.finetuning_validator.config": {"validate_core": true, "validate_nlu": true}
B4: Update của core: "predict_schema.nodes.run_RegexMessageHandler.need": {"messages": "run_ResponseSelector4", "domain: "domain_provider"}
B5: Update của core: {"training_type": 3}

2. Copy toàn bộ thư mục từ root components của nlu vào components của core
"""

"""
Update file nlu: data/intent/booking.yml, data/intent/other.yml, data/lookup_tables.yml, data/regex.yml, data/synonyms.yml
"""
