DEFAULT_PROMPT = "đặt xe đặt vé đặt chuyến đi thái nguyên, không có đúng sai huỷ đặt đón một hai ba bốn năm sáu bẩy tám chín"
DEFAULT_HOTWORDS = (
    "đặt xe, đặt vé, đặt chuyến, sửa, hủy, bỏ đi, đúng rồi, sai rồi, không đúng"
)

# Ánh xạ State với Initial Prompt
PROMPT_MAPPING = {
    "in_process": "chắc chắn có, hủy đi với đồng ý",
    "post_process": "tôi muốn giữ sửa đồng ý hoặc hủy từ chối bỏ đi",
    "cancel_process": "có, hủy, đồng ý, bỏ cái vé, không, từ chối, giữ lại",
    "modifi_process": "sửa điểm đón, đổi điểm đến, thay đổi thời gian, đổi số lượng, sửa tên",
    "confirm_form": "đúng rồi, vâng, ok, chuẩn rồi, sai rồi, không đúng, sửa lại",
    "diem_don": "cho mình điểm đón ở tại chỗ timescity",
    "diem_den": "đưa mình điểm đến là royalcity",
    "thoi_gian": "đón lúc chín giờ thứ hai tuần này",
    "so_luong": "đi bảy người",
    "dien_thoai": "số điện thoại mình là 0123456789",
    "ho_ten": "anh tên là, tên chị là, mình tên là",
    "loai_xe": "đi loại xe limousine",
}

# Ánh xạ State với Hot Word
HOTWORDS_MAPPING = {
    "in_process": "không, hủy, có, đồng ý, ừ, bỏ đi",
    "post_process": "có, hủy, đồng ý, bỏ cái vé, chốt",
    "cancel_process": "có, hủy, đồng ý, bỏ cái vé, không, từ chối, giữ lại",
    "modifi_process": "sửa điểm đón, đổi điểm đến, thay đổi thời gian, đổi số lượng, sửa tên",
    "confirm_form": "đúng rồi, vâng, ok, chuẩn rồi, sai rồi, không đúng, sửa lại",
    "diem_don": "công viên, cầu giấy, bến xe, sân bay, ngã tư, khách sạn",
    "diem_den": "bệnh viện, đại học, văn phòng, nhà ga, sân bay, nội bài, kim mã, bạc liêu",
    "thoi_gian": "thứ hai, thứ ba, thứ tư, thứ năm, thứ sáu, thứ bẩy, chủ nhật, sáng, chiều, tối, giờ, kém, phút, rưỡi, mai, kìa, nay, kia",
    "so_luong": "một, hai, ba, bốn, năm, sáu, bảy, tám, chín, tư, bẩy, mươi vé, ghế, chỗ, người, suất",
    "dien_thoai": "không, một, hai, ba, bốn, năm, sáu, bảy, tám, chín, tư, bẩy, số điện thoại",
    "ho_ten": "tên là, nguyễn, trần, lê, phạm, hoàng, đức, thị",
    "loai_xe": "limousine",
}


class RasaPrompt:
    def __init__(
        self, initial_prompt=DEFAULT_PROMPT, hot_word=DEFAULT_HOTWORDS, state="default"
    ):
        self.initial_prompt = initial_prompt
        self.hot_word = hot_word
        self.state = state

    def process_response(self, response_text):
        """
        Hàm trung tâm: Nhận câu trả lời từ Rasa, tách State, chữ cần đọc (TTS)
        và cập nhật luôn initial_prompt + hot_word cho vòng lặp STT tiếp theo.
        """
        # 1. Xử lý tách state và tts text
        if "|" in response_text:
            state_part, clean_tts_text = response_text.split("|", 1)
            self.state = state_part.strip().lower()
            clean_tts_text = clean_tts_text.strip()
        else:
            self.state = "default"
            clean_tts_text = response_text.strip()

        # 2. Cập nhật initial_prompt dựa trên dictionary mapping
        self.initial_prompt = PROMPT_MAPPING.get(self.state, DEFAULT_PROMPT)

        # 3. Cập nhật hot_word dựa trên dictionary mapping
        self.hot_word = HOTWORDS_MAPPING.get(self.state, DEFAULT_HOTWORDS)

        return self.state, clean_tts_text
