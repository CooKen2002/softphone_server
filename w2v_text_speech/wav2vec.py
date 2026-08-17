import numpy as np
import argparse
import soundfile as sf
import onnxruntime
import scipy

CHUNK_LENGTH = 20  # 20 seconds
MAX_N_SAMPLES = CHUNK_LENGTH * 16000

tokenizer_dict = {
    0: "ẻ",
    1: "6",
    2: "ụ",
    3: "í",
    4: "3",
    5: "ỹ",
    6: "ý",
    7: "ẩ",
    8: "ở",
    9: "ề",
    10: "õ",
    11: "7",
    12: "ê",
    13: "ứ",
    14: "ỏ",
    15: "v",
    16: "ỷ",
    17: "a",
    18: "l",
    19: "ự",
    20: "q",
    21: "ờ",
    22: "j",
    23: "ố",
    24: "à",
    25: "ỗ",
    26: "n",
    27: "é",
    28: "ủ",
    29: "у",
    30: "ô",
    31: "u",
    32: "y",
    33: "ằ",
    34: "4",
    35: "w",
    36: "b",
    37: "ệ",
    38: "ễ",
    39: "s",
    40: "ì",
    41: "ầ",
    42: "ỵ",
    43: "8",
    44: "d",
    45: "ể",
    47: "r",
    48: "ũ",
    49: "c",
    50: "ạ",
    51: "9",
    52: "ế",
    53: "ù",
    54: "ỡ",
    55: "2",
    56: "t",
    57: "i",
    58: "g",
    59: "́",
    60: "ử",
    61: "̀",
    62: "á",
    63: "0",
    64: "ậ",
    65: "e",
    66: "ộ",
    67: "m",
    68: "ẳ",
    69: "ợ",
    70: "ĩ",
    71: "h",
    72: "â",
    73: "ú",
    74: "ọ",
    75: "ồ",
    76: "ặ",
    77: "f",
    78: "ữ",
    79: "ắ",
    80: "ỳ",
    81: "x",
    82: "ó",
    83: "ã",
    84: "ổ",
    85: "ị",
    86: "",
    87: "z",
    88: "ả",
    89: "đ",
    90: "è",
    91: "ừ",
    92: "ò",
    93: "ẵ",
    94: "1",
    95: "ơ",
    96: "k",
    97: "ẫ",
    98: "p",
    99: "ấ",
    100: "ẽ",
    101: "ỉ",
    102: "ớ",
    103: "ẹ",
    104: "ă",
    105: "o",
    106: "ư",
    107: "5",
    46: "|",
    108: "<unk>",
    109: "<pad>",
}


def ensure_sample_rate(waveform, original_sample_rate, desired_sample_rate=16000):
    if original_sample_rate != desired_sample_rate:
        print(
            "resample_audio: {} HZ -> {} HZ".format(
                original_sample_rate, desired_sample_rate
            )
        )
        desired_length = int(
            round(float(len(waveform)) / original_sample_rate * desired_sample_rate)
        )
        waveform = scipy.signal.resample(waveform, desired_length)
    return waveform, desired_sample_rate


def ensure_channels(waveform, original_channels, desired_channels=1):
    if original_channels != desired_channels:
        print("convert_channels: {} -> {}".format(original_channels, desired_channels))
        waveform = np.mean(waveform, axis=1)
    return waveform, desired_channels


def init_model(model_path, target=None, device_id=None):
    if model_path.endswith(".onnx"):
        model = onnxruntime.InferenceSession(
            model_path, providers=["CPUExecutionProvider"]
        )

    return model


def run_model(model, audio_array):
    if "onnx" in str(type(model)):
        outputs = model.run(None, {model.get_inputs()[0].name: audio_array})[0]

    return outputs


def release_model(model):
    if "onnx" in str(type(model)):
        del model
    model = None


def pre_process(audio_array, max_length, pad_value=0):
    array_length = len(audio_array)

    if array_length < max_length:
        pad_length = max_length - array_length
        audio_array = np.pad(
            audio_array, (0, pad_length), mode="constant", constant_values=pad_value
        )
    elif array_length > max_length:
        audio_array = audio_array[:max_length]

    return audio_array


def compress_sequence(sequence):
    compressed_sequence = [sequence[0]]

    for i in range(1, len(sequence)):
        if sequence[i] != sequence[i - 1]:
            compressed_sequence.append(sequence[i])

    return compressed_sequence


def decode(token_ids):
    token_ids = compress_sequence(token_ids)
    transcriptions = []

    for token_id in token_ids:
        if token_id == 46 or token_id == 108 or token_id == 109:
            if token_id == 46:
                transcriptions.append(" ")
            continue
        token = tokenizer_dict[token_id]
        transcriptions.append(token)

    transcription = "".join(transcriptions)
    return transcription


def post_process(output):
    predicted_ids = np.argmax(output, axis=-1)
    transcription = decode(predicted_ids[0])
    return transcription


if __name__ == "__main__":
    # model_path = "wav2vec2_base_960h_20s.onnx"
    model_path = "../model/wav2vec2_vietnamese.onnx"
    # Set inputs
    audio_data, sample_rate = sf.read("2.mp3")
    channels = audio_data.ndim
    audio_data, channels = ensure_channels(audio_data, channels)
    audio_data, sample_rate = ensure_sample_rate(audio_data, sample_rate)
    audio_array = np.array(audio_data, dtype=np.float32)
    audio_array = pre_process(audio_array, MAX_N_SAMPLES)
    audio_array = np.expand_dims(audio_array, axis=0)

    # Init model
    model = init_model(model_path, None, None)
    # model.run()
    # Run model
    outputs = run_model(model, audio_array)

    # Post process
    transcription = post_process(outputs)
    print("\nWav2vec2 output:", transcription)

    # Release model
    release_model(model)
