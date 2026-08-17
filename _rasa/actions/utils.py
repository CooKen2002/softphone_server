from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import re

from .constants import *
from .services import *


def extract_entity(value):
    slots = []
    for entity, word in ENTITIES.items():
        for keywword in word:
            if keywword in value:
                slots.append(entity)
            break
    return slots


# MARK: VALIDATION
def valid_dia_diem(slot_value, entity, text):
    den_pattern = r"(kết thúc tại|xuống|sang|đến|tới|lên|về|ra|đi)(\s+)?(?:là|ở)?"
    don_pattern = r"(xuất phát từ|khởi hành từ|bắt đầu từ|đón ở|đi từ|lấy ở|rời|tại|từ|ở)(\s+)?(?:là|là tại)?"
    start = entity.get("start")
    end = entity.get("end")

    prefix = text[max(0, start - 15) : start].strip()
    print(prefix)
    if re.search(den_pattern, prefix):
        return [slot_value, "diem_den"]
    elif re.search(don_pattern, prefix):
        return [slot_value, "diem_don"]

    return [slot_value, "undetected"]


def valid_ho_ten(slot_value, entity):
    # logic kiem tra hoac format
    if entity.get("extractor") == DIET_CLASSIFIER:
        if float(entity.get("confidence_entity")) < 0.25:
            return None
    return slot_value


def valid_thoi_gian(slot_value, entity):
    # if entity.get("extractor") == DIET_CLASSIFIER:
    #     if float(entity.get("confidence_entity")) < 0.85:
    #         return None
    return slot_value


def valid_loai_xe(slot_value, entity):
    # if entity.get("extractor") == DIET_CLASSIFIER:
    #     if float(entity.get("confidence_entity")) < 0.85:
    #         return None
    # logic kiem tra hoac format
    return slot_value


def valid_so_luong(slot_value, entity):
    # if entity.get("extractor") == DIET_CLASSIFIER:
    #     if float(entity.get("confidence_entity")) < 0.85:
    #         return None
    # logic kiem tra hoac format
    raw_num = re.match(r"^(\S+)", slot_value.strip())
    if not raw_num:
        return None
    num = raw_num.group(1).lower()
    # lấy int của phần tử đầu
    if num.isdigit():
        return int(num)
    else:
        return text_to_int(num)


def valid_dien_thoai(slot_value, entity):
    # if entity.get("extractor") == DIET_CLASSIFIER:
    #     if float(entity.get("confidence_entity")) < 0.85:
    #         return None
    # logic valid sdt

    sdt = re.sub(r"[.\-\s]", "", slot_value)
    # check sdt valid ?
    if len(sdt) < 10 or len(sdt) > 11:
        return None

    return sdt


# Hàm lây danh sách vé từ số điện thoại
# Lấy từ call bên db mongo
def get_list_from_phone(phone):

    # TODO: Thêm call đến db lấy vé port 27017
    ticket_list_from_db = MOCK_TICKETS

    ticket_list = []
    for ticket in ticket_list_from_db:
        if ticket.get("dien_thoai") == phone:
            ticket_list.append(ticket)

    return ticket_list


def get_list_from_phone_at_server(sender, phone):
    ticket_list_from_db = seachBookingBySenderAndPhone(sender, phone)
    # print(ticket_list_from_db)
    return ticket_list_from_db


def get_list_dynamic(list_tickets, field, value):
    new_list = []
    if list_tickets:
        for lt in list_tickets:
            if lt.get(field) == value:
                new_list.append(lt)

    return new_list


# MARK: PHRASES RUNTIME


def add_to_phrases_runtime_txt(file_path, section_name, new_value):
    marker = f"# {section_name}"

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Kiểm tra xem giá trị đã tồn tại chưa để tránh trùng lặp
    if any(new_value == line.strip() for line in lines):
        return False  # Đã tồn tại

    new_lines = []
    inserted = False
    in_target_section = False

    for line in lines:
        new_lines.append(line)

        # Nếu gặp đúng tiêu đề section
        if line.strip() == marker:
            in_target_section = True
            continue

        # Nếu đang ở trong section đó và chưa chèn, hoặc gặp section mới
        if in_target_section:
            # Nếu gặp dòng trống hoặc dòng bắt đầu bằng # (sang section mới), chèn vào trước đó
            if line.strip() == "" or line.startswith("#"):
                new_lines.insert(-1, f"{new_value}\n")
                inserted = True
                in_target_section = False  # Thoát vùng chèn

    # Trường hợp nếu section nằm cuối file
    if not inserted and in_target_section:
        new_lines.append(f"{new_value}\n")
        inserted = True

    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    return True


# MARK: UTIL TIME
def parse_vietnamese_datetime(text, now=None):
    if now is None:
        now = datetime.now()

    text = text.lower().strip()

    # =========================================================
    # CASE: sau X tiếng / phút / ngày
    # =========================================================

    match_relative = re.search(r"sau\s+(\d+)\s*(giờ|tiếng|phút|ngày)", text)

    if match_relative:
        value = int(match_relative.group(1))
        unit = match_relative.group(2)

        if unit in ["giờ", "tiếng"]:
            return now + timedelta(hours=value)

        elif unit == "phút":
            return now + timedelta(minutes=value)

        elif unit == "ngày":
            return now + timedelta(days=value)

    # =========================================================
    # Base date
    # =========================================================

    target_date = now.date()

    # =========================================================
    # Relative day
    # =========================================================

    if "ngày kia" in text or "mốt" in text:
        target_date += timedelta(days=2)

    elif "mai" in text:
        target_date += timedelta(days=1)

    # =========================================================
    # tuần sau
    # =========================================================

    if "tuần sau" in text:
        target_date += timedelta(days=7)

    # =========================================================
    # tháng sau
    # =========================================================

    if "tháng sau" in text:
        temp = datetime.combine(target_date, datetime.min.time())
        temp += relativedelta(months=1)
        target_date = temp.date()

    # =========================================================
    # Parse weekday
    # =========================================================

    found_weekday = None

    for key, value in WEEKDAYS.items():  # thiếu định nghĩa WEEKDAYS
        if key in text:
            found_weekday = value
            break

    if found_weekday is not None:
        current_weekday = now.weekday()

        days_ahead = found_weekday - current_weekday

        if days_ahead <= 0:
            days_ahead += 7

        # Nếu có "tuần sau" thì + thêm 7 ngày
        if "tuần sau" in text:
            days_ahead += 7

        target_date = (now + timedelta(days=days_ahead)).date()

    # =========================================================
    # cuối tuần
    # =========================================================

    if "cuối tuần" in text:
        saturday = 5

        current_weekday = now.weekday()

        days_ahead = saturday - current_weekday

        if days_ahead <= 0:
            days_ahead += 7

        if "tuần sau" in text:
            days_ahead += 7

        target_date = (now + timedelta(days=days_ahead)).date()

    # =========================================================
    # Parse hour/minute
    # =========================================================

    hour = 0
    minute = 0

    # hỗ trợ:
    # 4h
    # 4 giờ
    # 4h30
    # 4 giờ 30
    match = re.search(r"(\d+)\s*(?:giờ|h)(?:\s*(\d+))?", text)

    if match:
        hour = int(match.group(1))
        minute = int(match.group(2) or 0)

    # =========================================================
    # sáng / chiều / tối
    # =========================================================

    if any(x in text for x in ["chiều", "tối"]):
        if hour < 12:
            hour += 12

    elif "trưa" in text:
        if hour < 11:
            hour += 12

    elif "đêm" in text:
        if hour == 12:
            hour = 0

    # =========================================================
    # Build datetime
    # =========================================================

    result = datetime.combine(target_date, datetime.min.time())

    result = result.replace(hour=hour, minute=minute, second=0, microsecond=0)

    return result


def text_to_int(text):
    units = {
        "không": 0,
        "một": 1,
        "hai": 2,
        "ba": 3,
        "bốn": 4,
        "năm": 5,
        "sáu": 6,
        "bảy": 7,
        "tám": 8,
        "chín": 9,
    }
    tens = {
        "mười": 10,
        "hai mươi": 20,
        "ba mươi": 30,
        "bốn mươi": 40,
        "năm mươi": 50,
        "sáu mươi": 60,
        "bảy mươi": 70,
        "tám mươi": 80,
        "chín mươi": 90,
    }

    text = text.lower().strip()

    # Trường hợp số đơn lẻ
    if text in units:
        return units[text]

    # Trường hợp số tròn chục (mười, hai mươi...)
    if text in tens:
        return tens[text]

    # Trường hợp số có hai chữ số (vd: hai mươi lăm)
    parts = text.split(" ")
    if len(parts) == 3 and parts[1] == "mươi":
        return tens[parts[0] + " mươi"] + units.get(parts[2], 0)

    # Trường hợp đặc biệt (mười lăm, hai mươi mốt...)
    if "mười" in text:
        return 10 + units.get(text.replace("mười ", ""), 0)

    return None