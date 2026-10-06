import subprocess
import requests
import time
from config import *

def rasa_scripts(rasa_session=None, wait_seconds=90, poll_interval=3):
    if rasa_session is None:
        rasa_session = requests.Session()

    payload = {"sender": SENDER_ID, "message": "xin chào"}

    def ping():
        try:
            res = rasa_session.post(RASA_URL, json=payload, timeout=3)
            return res.status_code == 200
        except Exception:
            return False

    if ping():
        return True

    subprocess.Popen(
        f'start "Rasa API" cmd /k "cd /d {RASA_PATH} && call .venv_rasa\\Scripts\\activate && rasa run --enable-api --cors \\"*\\" -vv"',
        shell=True,
    )
    subprocess.Popen(
        f'start "Rasa Actions" cmd /k "cd /d {RASA_PATH} && call .venv_rasa\\Scripts\\activate && rasa run actions -vv"',
        shell=True,
    )

    elapsed = 0
    while elapsed < wait_seconds:
        time.sleep(poll_interval)
        elapsed += poll_interval
        if ping():
            return True
    return False