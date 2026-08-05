import re


def clean_text(text):
    """
    Xóa dấu câu và từ vô nghĩa (stop words) khỏi văn bản.
    """
    # Đảm bảo đầu vào là kiểu chuỗi, tránh lỗi nếu gặp None hoặc kiểu dữ liệu khác
    if not isinstance(text, str):
        return ""

    vn_nonsense = {"àm", "ừm", "ờ", "unk"}  # Dùng set thay vì list để tra cứu nhanh hơn

    # 1. Chuyển về chữ thường
    text = text.lower()

    # 2. Xóa dấu câu bằng Regex
    # Sử dụng space thay vì chuỗi rỗng giúp tránh trường hợp dính từ (ví dụ: 'hello,world' -> 'hello world' thay vì 'helloworld')
    text = re.sub(r"[^\w\s]", " ", text)

    # 3. Chia nhỏ văn bản và lọc
    words = text.split()

    # 4. Lọc các từ vô nghĩa (dùng set giúp tốc độ xử lý nhanh hơn với dữ liệu lớn)
    cleaned_words = [word for word in words if word not in vn_nonsense]

    # 5. Kết nối lại
    return " ".join(cleaned_words)


# print(clean_text("Xin chào, ừm, tôi là unk. Hôm nay trời đẹp."))
