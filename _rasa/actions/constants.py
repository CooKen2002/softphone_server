# Định nghĩa Key (entity)
DIEM_DON = "diem_don"  # diemdon, diemDon, Diemdon, loc_to
DIEM_DEN = "diem_den"
THOI_GIAN = "thoi_gian"
LOAI_XE = "loai_xe"
SO_LUONG = "so_luong"
HO_TEN = "ho_ten"
DIEN_THOAI = "dien_thoai"
DIA_DIEM = "dia_diem"
REQUESTED_SLOT = "requested_slot"
LIST_TICKETS = "list_tickets"
HAS_LIST = "has_lists"
FLAG_FORM = "flag_form"
CONFIRM_FORM = "confirm_form"
KIEU_GHE = "kieu_ghe"
STATUS_FORM = "status_form"
PRE_PROCESS = "pre_process"
IN_PROCESS = "in_process"
POST_PROCESS = "post_process"
END_PROCESS = "end_process"
CANCEL_PROCESS = "cancel_process"
MODIFI_PROCESS = "modifi_process"
FORM_DAT_VE = "form_dat_ve"
FORM_SUA_VE = "form_sua_ve"
FORM_HUY_VE = "form_huy_ve"

STATUS_BOOKING = "status_booking"
MA_THOI_GIAN = "timeCode"
CANCEL = "huy"
SENDER = "sender"
ID = "_id"

# Định nghĩa key (intent)
CUNG_CAP_THONG_TIN = "cung_cap_thong_tin"
DAT_VE = "dat_ve"
DONG_Y = "dong_y"
HUY = "huy"
TU_CHOI = "tu_choi"
SUA_THONG_TIN = "sua_thong_tin"
CHAO_HOI = "chao_hoi"

# Định nghĩa các file path
PHRASES_RUNTIME_PATH = (
    r"./components/sks_tokenizer/phrases_runtime.txt"
)

DIET_CLASSIFIER = "DIETClassifier"
ENTITIES = {
    DIEM_DON: [
        "điểm đón",
        "vị trí hẹn",
        "điểm tập kết",
    ],
    DIEM_DEN: [
        "điểm đến",
        "đích đến",
        "nơi đến",
    ],
    THOI_GIAN: ["thời gian", "lịch", "giờ", "ngày"],
    LOAI_XE: [
        "xe",
    ],
    SO_LUONG: [
        "số vé",
        "số người",
        "số ghế",
    ],
    HO_TEN: ["tên"],
    DIEN_THOAI: [
        "điện thoại",
        "liên lạc",
    ],
}

# Giả lập Database vé (MOCK_DB)
MOCK_TICKETS = [
    {
        "ho_ten": "trần",
        "dien_thoai": "0901234567",
        "diem_don": "hoàn kiếm",
        "diem_den": "hồ tây",
        "thoi_gian": "hôm nay",
        "loai_xe": "Giường nằm",
        "so_luong": 2,
    },
    {
        "ho_ten": "trần",
        "dien_thoai": "0901234567",
        "diem_don": "ninh bình",
        "diem_den": "cầu giấy",
        "thoi_gian": "hôm nay",
        "loai_xe": "Limousine",
        "so_luong": 1,
    },
    {
        "ho_ten": "trần",
        "dien_thoai": "0901234567",
        "diem_don": "hoàn kiếm",
        "diem_den": "hồ tây",
        "thoi_gian": "ngày mai",
        "loai_xe": "Giường nằm",
        "so_luong": 2,
    },
    {
        "ho_ten": "trần",
        "dien_thoai": "0901234567",
        "diem_don": "hoàn kiếm",
        "diem_den": "cầu giấy",
        "thoi_gian": "ngày mai",
        "loai_xe": "Limousine",
        "so_luong": 1,
    },
    {
        "ho_ten": "an",
        "dien_thoai": "0987654321",
        "diem_don": "ninh bình",
        "diem_den": "nha trang",
        "thoi_gian": "9 giờ",
        "loai_xe": "Phòng nằm VIP",
        "so_luong": 3,
    },
    {
        "ho_ten": "cường",
        "dien_thoai": "0988777666",
        "diem_don": "tây hồ",
        "diem_den": "ninh bình",
        "thoi_gian": "9 giờ sáng",
        "loai_xe": "Ghế ngồi",
        "so_luong": 1,
    },
    {
        "ho_ten": "đức",
        "dien_thoai": "0333444555",
        "diem_don": "hải phòng",
        "diem_den": "huế",
        "thoi_gian": "8 giờ",
        "loai_xe": "Limousine",
        "so_luong": 4,
    },
]

# định nghĩa weekdays tạm thời
WEEKDAYS = {
    "thứ 2": "0",
    "thứ 3": "1",
    "thứ 4": "2",
    "thứ 5": "3",
    "thứ 6": "4",
    "thứ 7": "5",
    "chủ nhật": "6",
}
