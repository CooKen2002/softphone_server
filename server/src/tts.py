"""
AssetTTS - TTS ưu tiên file WAV có sẵn, chỉ gọi model cho phần chưa có.

Luồng xử lý một câu trả lời của Rasa:
  1. Chuẩn hoá text (NFC, chữ thường, bỏ dấu câu) rồi tách thành từ.
  2. Duyệt từ trái sang phải, tại mỗi vị trí lấy cụm DÀI NHẤT trùng với một
     key trong assets/audio  -> dùng WAV có sẵn.
  3. Các từ không khớp cụm nào được gom lại (tách theo . ! ? ; xuống dòng)
     rồi mới đưa vào model TTS.
  4. Ghép tất cả theo đúng thứ tự, chèn khoảng lặng ngắn giữa các đoạn,
     trả về WAV 8kHz / mono / 16-bit (bytes) để gửi thẳng cho softphone.

Cấu trúc assets (giữ nguyên như bản cũ):
    assets/audio/<thư mục con>/audio.json   {"đón tại:": "don_tai.wav", ...}
    assets/audio/audio.json                 (cũng được)
    assets/audio/<text>.wav                 (kiểu cũ: tên file chính là text)

Key kết thúc bằng ":" được coi là NHÃN ("đón tại:", "giờ:"...). Nhãn chỉ khớp
khi trong text cũng có ":" ngay sau nó (hoặc nhãn đứng riêng thành một câu).

Chạy thử không cần model:  python tts.py "text cần đọc" --plan-only
"""

from __future__ import annotations

import argparse
import io
import json
import math
import re
import threading
import unicodedata
import wave
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

_WORD_RE = re.compile(r"\w+", re.UNICODE)
_HARD_CHARS = frozenset(".!?;…\n")  # ranh giới câu: không gộp TTS qua đây


def _default_log(msg: str, level: str = "INFO") -> None:
    print(f"[{level}] {msg}")


# ----------------------------------------------------------------------
# Tách từ / chuẩn hoá
# ----------------------------------------------------------------------
@dataclass(frozen=True)
class _Tok:
    word: str   # đã NFC + lower
    start: int  # vị trí trong text đã NFC
    end: int


def _tokenize(text: str) -> tuple[str, list[_Tok]]:
    # NFC TRƯỚC khi tách: \w không bắt dấu kết hợp (NFD) nên sẽ cắt đôi chữ có dấu.
    text = unicodedata.normalize("NFC", text)
    toks = [_Tok(m.group().lower(), m.start(), m.end()) for m in _WORD_RE.finditer(text)]
    return text, toks


def _norm_key(text: str) -> str:
    return " ".join(t.word for t in _tokenize(text)[1])


# ----------------------------------------------------------------------
# Âm thanh
# ----------------------------------------------------------------------
def _resample(x: np.ndarray, src_sr: int, dst_sr: int) -> np.ndarray:
    if src_sr == dst_sr or len(x) == 0:
        return x.astype(np.float32, copy=False)
    g = math.gcd(int(src_sr), int(dst_sr))
    return resample_poly(x, dst_sr // g, src_sr // g).astype(np.float32)


def _to_int16(x: np.ndarray) -> np.ndarray:
    return (np.clip(x, -1.0, 1.0) * 32767.0).astype(np.int16)


def _read_clip(path: Path, target_sr: int) -> np.ndarray:
    """Đọc WAV bất kỳ (8/16/24/32-bit, float, stereo...) -> int16 mono @ target_sr."""
    data, sr = sf.read(str(path), dtype="float32", always_2d=True)
    mono = data.mean(axis=1)
    return _to_int16(_resample(mono, sr, target_sr))


def _wav_bytes(pcm: np.ndarray, sr: int) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(np.ascontiguousarray(pcm, dtype="<i2").tobytes())
    return buf.getvalue()


# ----------------------------------------------------------------------
# Thư viện WAV + kế hoạch đọc
# ----------------------------------------------------------------------
@dataclass
class _Clip:
    key: str            # text đã chuẩn hoá
    label: bool         # key gốc kết thúc bằng ":"
    path: str
    audio: np.ndarray   # int16 mono @ target_sr


@dataclass
class _Seg:
    kind: str                    # "wav" | "tts"
    text: str = ""               # nội dung đưa vào TTS (kind == "tts")
    clip: _Clip | None = None    # clip có sẵn (kind == "wav")
    hard_after: bool = False     # sau đoạn này là ranh giới câu


class AssetTTS:
    def __init__(
        self,
        model,
        assets_dir: str = "./assets/audio",
        voice: str = "Đoan Trang",
        target_sr: int = 8000,
        model_sr: int | None = None,
        pad_ms_dynamic: int = 350,   # đệm đầu/cuối khi có đoạn do model sinh (giống bản cũ)
        pad_ms_recorded: int = 0,    # đệm đầu/cuối khi toàn bộ là WAV có sẵn
        gap_soft_ms: int = 60,       # nghỉ giữa các đoạn trong cùng một câu (vd nhãn -> giá trị)
        gap_hard_ms: int = 180,      # nghỉ giữa các câu
        cache_size: int = 256,       # cache đoạn TTS đã sinh (0 = tắt)
        log=None,
    ):
        self.model = model
        self.assets_dir = Path(assets_dir)
        self.voice = voice
        self.target_sr = target_sr
        self.pad_ms_dynamic = pad_ms_dynamic
        self.pad_ms_recorded = pad_ms_recorded
        self.gap_soft_ms = gap_soft_ms
        self.gap_hard_ms = gap_hard_ms
        self.cache_size = cache_size
        self._log = log or _default_log

        if model_sr is None:
            try:
                model_sr = int(getattr(model, "sample_rate", 0)) or 48000
            except (TypeError, ValueError):
                model_sr = 48000
        self.model_sr = model_sr

        self._infer_lock = threading.Lock()   # model TTS không đảm bảo thread-safe
        self._cache_lock = threading.Lock()
        self._cache: OrderedDict[str, np.ndarray] = OrderedDict()

        self.clips: dict[str, _Clip] = {}
        self.max_words = 1
        self.reload()

    # ------------------------------------------------------------------
    def reload(self) -> None:
        """Nạp lại toàn bộ WAV vào RAM (gọi lại khi thêm/sửa file trong assets)."""
        clips: dict[str, _Clip] = {}
        missing = bad = dup = 0

        for raw_text, path in self._iter_index():
            key = _norm_key(raw_text)
            if not key:
                continue
            if key in clips:
                dup += 1
                self._log(f"Trùng key '{key}': giữ {clips[key].path}, bỏ {path}", "TTS")
                continue
            if not path.is_file():
                missing += 1
                self._log(f"Thiếu file WAV cho '{raw_text}': {path}", "ERROR")
                continue
            try:
                audio = _read_clip(path, self.target_sr)
            except Exception as e:  # file hỏng không được làm sập cả server
                bad += 1
                self._log(f"Không đọc được {path}: {e}", "ERROR")
                continue
            clips[key] = _Clip(key, raw_text.strip().endswith(":"), str(path), audio)

        self.clips = clips
        self.max_words = max((len(k.split()) for k in clips), default=1)
        self._log(
            f"Assets TTS: {len(clips)} WAV @ {self.target_sr}Hz "
            f"(cụm dài nhất {self.max_words} từ; thiếu {missing}, lỗi {bad}, trùng {dup})",
            "TTS",
        )

    def _iter_index(self):
        root = self.assets_dir
        if not root.is_dir():
            self._log(f"Không thấy thư mục assets audio: {root}", "ERROR")
            return
        for idx in sorted(root.rglob("audio.json")):
            try:
                mapping = json.loads(idx.read_text(encoding="utf-8"))
            except Exception as e:
                self._log(f"Không đọc được {idx}: {e}", "ERROR")
                continue
            for text, fname in mapping.items():
                yield text, idx.parent / fname
        for wav_path in sorted(root.glob("*.wav")):  # kiểu cũ: tên file = text
            yield wav_path.stem, wav_path

    # ------------------------------------------------------------------
    def plan(self, text: str) -> list[_Seg]:
        """Chia text thành các đoạn: WAV có sẵn hoặc đoạn cần TTS."""
        text, toks = _tokenize(text or "")
        n = len(toks)
        if n == 0:
            return []

        hard_after, colon_after = [], []
        for i, t in enumerate(toks):
            gap = text[t.end: toks[i + 1].start] if i + 1 < n else text[t.end:]
            hard_after.append(i == n - 1 or any(c in _HARD_CHARS for c in gap))
            colon_after.append(":" in gap)
        hard_before = [True] + hard_after[:-1]

        segs: list[_Seg] = []

        def flush(a: int, b: int) -> None:
            """Đoạn từ chưa khớp WAV toks[a:b] -> TTS, tách tại ranh giới câu."""
            s = a
            for k in range(a, b):
                if hard_after[k]:
                    segs.append(_Seg("tts", text[toks[s].start: toks[k].end], hard_after=True))
                    s = k + 1
            if s < b:
                segs.append(_Seg("tts", text[toks[s].start: toks[b - 1].end], hard_after=hard_after[b - 1]))

        i, pending = 0, None
        while i < n:
            clip, k = None, 0
            for length in range(min(self.max_words, n - i), 0, -1):
                cand = self.clips.get(" ".join(t.word for t in toks[i: i + length]))
                if cand is None:
                    continue
                j = i + length - 1
                covers = hard_before[i] and hard_after[j]  # khớp trọn một câu
                if cand.label:
                    ok = colon_after[j] or covers
                elif length == 1:
                    ok = covers  # 1 từ lẻ giữa câu: không chèn WAV, tránh giọng bị chắp vá
                else:
                    ok = True
                if ok:
                    clip, k = cand, length
                    break

            if clip is None:
                if pending is None:
                    pending = i
                i += 1
                continue

            if pending is not None:
                flush(pending, i)
                pending = None
            j = i + k - 1
            segs.append(_Seg("wav", clip=clip, hard_after=hard_after[j] and not colon_after[j]))
            i += k

        if pending is not None:
            flush(pending, n)
        return segs

    @staticmethod
    def describe(segs: list[_Seg]) -> str:
        return " + ".join(
            f"[WAV {s.clip.key}]" if s.kind == "wav" else f"[TTS {s.text}]" for s in segs
        )

    # ------------------------------------------------------------------
    def synthesize(self, text: str) -> bytes:
        """Text -> WAV bytes (8kHz mono 16-bit). Hàm chặn (blocking): gọi qua run_in_executor."""
        segs = self.plan(text)
        self._log(f"Kế hoạch: {self.describe(segs) or '(rỗng)'}", "TTS")

        if not segs:
            return _wav_bytes(self._silence(max(self.pad_ms_dynamic, 200)), self.target_sr)

        has_tts = any(s.kind == "tts" for s in segs)
        pad = self._silence(self.pad_ms_dynamic if has_tts else self.pad_ms_recorded)

        parts = [pad]
        for idx, seg in enumerate(segs):
            audio = seg.clip.audio if seg.kind == "wav" else self._tts_chunk(seg.text)
            if len(audio):
                parts.append(audio)
            if idx < len(segs) - 1:
                parts.append(self._silence(self.gap_hard_ms if seg.hard_after else self.gap_soft_ms))
        parts.append(pad)

        return _wav_bytes(np.concatenate(parts), self.target_sr)

    def warmup(self) -> None:
        """Chạy thử model một lần để lần gọi thật đầu tiên không bị chậm."""
        self._tts_chunk("xin chào")

    # ------------------------------------------------------------------
    def _silence(self, ms: int) -> np.ndarray:
        return np.zeros(int(self.target_sr * ms / 1000), dtype=np.int16)

    def _tts_chunk(self, text: str) -> np.ndarray:
        key = text.strip()
        if not key:
            return np.zeros(0, dtype=np.int16)

        if self.cache_size > 0:
            with self._cache_lock:
                hit = self._cache.get(key)
                if hit is not None:
                    self._cache.move_to_end(key)
                    return hit

        with self._infer_lock:
            if self.cache_size > 0:  # luồng khác có thể vừa sinh xong đúng câu này
                with self._cache_lock:
                    hit = self._cache.get(key)
                if hit is not None:
                    return hit
            raw = self.model.infer(text=key, voice=self.voice)
        audio = _to_int16(_resample(np.asarray(raw, dtype=np.float32).reshape(-1), self.model_sr, self.target_sr))

        if self.cache_size > 0:
            audio.setflags(write=False)
            with self._cache_lock:
                self._cache[key] = audio
                while len(self._cache) > self.cache_size:
                    self._cache.popitem(last=False)
        return audio


# ----------------------------------------------------------------------
# CLI thử nhanh
# ----------------------------------------------------------------------
if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Thử AssetTTS")
    ap.add_argument("text")
    ap.add_argument("--assets", default="./assets/audio")
    ap.add_argument("--out", default="./results/tts_test.wav")
    ap.add_argument("--plan-only", action="store_true", help="chỉ in kế hoạch, không nạp model")
    args = ap.parse_args()

    if args.plan_only:
        engine = AssetTTS(None, assets_dir=args.assets)
        print(engine.describe(engine.plan(args.text)))
    else:
        from vieneu import Vieneu

        engine = AssetTTS(Vieneu(), assets_dir=args.assets)
        data = engine.synthesize(args.text)
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(data)
        print(f"Đã lưu {out} ({len(data) / 1024:.1f} KB)")
