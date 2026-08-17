import re
import ast
from datetime import datetime

ANSI_ESCAPE = re.compile(r'\x1b\[[0-9;]*m')
LOG_TIMESTAMP = re.compile(r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})')  # vd: 2026-05-23 15:32:38

log_path      = r"./logs/server_debug.log"
output_path   = r"./scripts/diet_result.txt"
last_run_path = r"./scripts/.last_run"  # file lưu timestamp

# --- Đọc timestamp lần chạy trước (nếu có) ---
try:
    with open(last_run_path, 'r') as f:
        last_run = datetime.strptime(f.read().strip(), '%Y-%m-%d %H:%M:%S')
except FileNotFoundError:
    last_run = None  # lần đầu chạy → đọc toàn bộ log

time_run_scripts = datetime.now()

# --- Parse log ---
results = []

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        # Lọc theo timestamp của dòng log
        ts_match = LOG_TIMESTAMP.match(line)
        if ts_match:
            log_time = datetime.strptime(ts_match.group(1), '%Y-%m-%d %H:%M:%S')
            if last_run and log_time <= last_run:
                continue  # bỏ qua dòng cũ

        if "processor.message.parse" in line:
            clean = ANSI_ESCAPE.sub('', line)

            entities_match = re.search(r"parse_data_entities=(.*?) parse_data_intent=", clean)
            intent_match   = re.search(r"parse_data_intent=(.*?) parse_data_text=", clean)
            text_match     = re.search(r"parse_data_text=(.*)$", clean)

            if entities_match and intent_match and text_match:
                entities = ast.literal_eval(entities_match.group(1).strip())
                intent   = ast.literal_eval(intent_match.group(1).strip())
                text     = text_match.group(1).strip()

                results.append(
                    f"Text    : {text}\n"
                    f"Intent  : {intent['name']} ({intent['confidence']:.2f})\n"
                    f"Entities: {entities}\n"
                )

# --- Ghi kết quả ---
with open(output_path, 'a', encoding='utf-8') as f:
    f.write(f"{time_run_scripts.strftime('%Y-%m-%d %H:%M:%S')} | {len(results)} messages\n")
    if results:
        f.write('\n'.join(results))
    else:
        f.write("(Không có message mới)\n")
    f.write('\n')

# --- Lưu timestamp lần chạy này cho lần sau ---
with open(last_run_path, 'w') as f:
    f.write(time_run_scripts.strftime('%Y-%m-%d %H:%M:%S'))

print(f"✅ {len(results)} message mới | Last run: {last_run or 'lần đầu'}")