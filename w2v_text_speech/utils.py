from datetime import datetime

def log(msg: str, level: str = "INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    color = {
        "INFO": "36",  # Cyan
        "STT": "32",  # Green
        "TTS": "35",  # Magenta
        "RASA": "33",  # Yellow
        "ERROR": "31",  # Red
        "AUDIO": "34",  # Blue
    }.get(level, "37")
    print(f"\033[{color}m[{timestamp}] {level:5} | {msg}\033[0m")
