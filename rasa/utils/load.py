import json
from typing import Any, Dict, List, Text
from pathlib import Path


def load_json(path):

    if not path.exists():
        return {}

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_txt(path):

    if not path.exists():
        return {}

    with open(path, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


def load_phrases(path):

    if not path.exists():
        return []

    with open(path, "r", encoding="utf-8") as f:
        return [line.strip().lower() for line in f if line.strip()]
