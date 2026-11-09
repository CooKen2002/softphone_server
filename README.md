# 🏗️ System Architecture & Getting Started Example

## 🏗️ System Architecture

Hệ thống **Softphone Server** đóng vai trò là lõi xử lý trung gian giữa client cuộc gọi (SIP/WebSocket) và các engine AI (STT, NLU, TTS) để xử lý hội thoại bằng giọng nói theo thời gian thực với độ trễ thấp.

### 1. High-Level Data Flow Diagram

```text
  [ Client (Flutter / SIP) ]
              │
              │ 1. Continuous Audio Stream (PCM 16kHz) / SIP Signals
              ▼
    +-------------------+
    | WebSocket / SIP   |
    | Gateway           |
    +---------+---------+
              │
              │ 2. Audio Chunks
              ▼
    +-------------------+      3. Voice Activity Detected      +-------------------+
    | Audio DSP & VAD   | ───────────────────────────────────> | STT Engine        |
    | (Silero / Speex)  |                                      | (Faster-Whisper)  |
    +-------------------+                                      +---------+---------+
                                                                         │
                                                                         │ 4. Transcribed Text
                                                                         ▼
    +-------------------+      6. Synthesized Audio Wave       +-------------------+
    | TTS Engine        | <─────────────────────────────────── | Rasa NLU Core     |
    | (VieNeu TTS)      |                                      | & Custom Actions  |
    +---------+---------+                                      +-------------------+
              │
              │ 5. Response Audio Stream
              ▼
  [ Client (Flutter / SIP) ]