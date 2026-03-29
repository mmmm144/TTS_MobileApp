import os
import torch
import torchaudio
import whisper
import warnings
import numpy as np
import matplotlib.pyplot as plt
import librosa
import librosa.display
from torch.nn import CosineSimilarity
from transformers import Wav2Vec2FeatureExtractor, WavLMForXVector
from difflib import SequenceMatcher

warnings.filterwarnings("ignore")
REF_WAV = "01_0029_s29.wav"
REF_TEXT_FILE = "text.txt"
RESULT_DIR = "ket_qua_so_sanh_meta" 
OUTPUT_IMAGE_DIR = "bieu_do_bao_cao" 

CANDIDATES = [
    "1_AnhNH_Community.wav",
    "2_Nhat1106_finetuned.wav",
    "3_Meta_MMS_Base.wav"
]

def calculate_wer(reference, hypothesis):
    r = reference.lower().split()
    h = hypothesis.lower().split()
    d = [[0] * (len(h) + 1) for _ in range(len(r) + 1)]
    for i in range(len(r) + 1): d[i][0] = i
    for j in range(len(h) + 1): d[0][j] = j
    for i in range(1, len(r) + 1):
        for j in range(1, len(h) + 1):
            if r[i-1] == h[j-1]: d[i][j] = d[i-1][j-1]
            else: d[i][j] = min(d[i-1][j-1], d[i][j-1], d[i-1][j]) + 1
    return float(d[len(r)][len(h)]) / max(1, len(r))

def calculate_cer(reference, hypothesis):
    r = list(reference.lower())
    h = list(hypothesis.lower())
    d = [[0] * (len(h) + 1) for _ in range(len(r) + 1)]
    for i in range(len(r) + 1): d[i][0] = i
    for j in range(len(h) + 1): d[0][j] = j
    for i in range(1, len(r) + 1):
        for j in range(1, len(h) + 1):
            if r[i-1] == h[j-1]: d[i][j] = d[i-1][j-1]
            else: d[i][j] = min(d[i-1][j-1], d[i][j-1], d[i-1][j]) + 1
    return float(d[len(r)][len(h)]) / max(1, len(r))

def color_diff(ref, hyp):
    matcher = SequenceMatcher(None, ref.lower().split(), hyp.lower().split())
    result = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == 'equal':
            result.append("\033[92m" + " ".join(ref.lower().split()[i1:i2]) + "\033[0m")
        elif tag == 'replace':
            result.append("\033[91m" + f"[{' '.join(hyp.lower().split()[j1:j2])}]" + "\033[0m")
        elif tag == 'delete':
            result.append("\033[91m" + f"(-{' '.join(ref.lower().split()[i1:i2])})" + "\033[0m")
        elif tag == 'insert':
            result.append("\033[91m" + f"(+{' '.join(hyp.lower().split()[j1:j2])})" + "\033[0m")
    return " ".join(result)

def draw_spectrogram_comparison(ref_path, gen_path, model_name, save_path):
    y_ref, sr_ref = librosa.load(ref_path, sr=22050)
    y_gen, sr_gen = librosa.load(gen_path, sr=22050)
    
    plt.figure(figsize=(12, 6))
    
    plt.subplot(2, 1, 1)
    D_ref = librosa.amplitude_to_db(np.abs(librosa.stft(y_ref)), ref=np.max)
    librosa.display.specshow(D_ref, sr=sr_ref, x_axis='time', y_axis='log')
    plt.colorbar(format='%+2.0f dB')
    plt.title(f'Spectrogram: Giọng Mẫu ({os.path.basename(ref_path)})')
    
    plt.subplot(2, 1, 2)
    D_gen = librosa.amplitude_to_db(np.abs(librosa.stft(y_gen)), ref=np.max)
    librosa.display.specshow(D_gen, sr=sr_gen, x_axis='time', y_axis='log')
    plt.colorbar(format='%+2.0f dB')
    plt.title(f'Spectrogram: {model_name}')
    
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()
    print(f"Đã lưu biểu đồ so sánh: {save_path}")

if __name__ == "__main__":
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    print(f"BẮT ĐẦU ĐÁNH GIÁ CHUYÊN SÂU ({device.upper()})...")
    
    os.makedirs(OUTPUT_IMAGE_DIR, exist_ok=True)
    
    print("⏳ Loading models...")
    wavlm_proc = Wav2Vec2FeatureExtractor.from_pretrained("microsoft/wavlm-base-plus-sv")
    wavlm_model = WavLMForXVector.from_pretrained("microsoft/wavlm-base-plus-sv").to(device)
    asr_model = whisper.load_model("small")
    cos_sim = CosineSimilarity(dim=1)

    with open(REF_TEXT_FILE, "r", encoding="utf-8") as f: text_ref = f.read().strip()
    
    wav_ref, sr = torchaudio.load(REF_WAV)
    if wav_ref.shape[0] > 1: wav_ref = torch.mean(wav_ref, dim=0, keepdim=True)
    if sr != 16000: wav_ref = torchaudio.transforms.Resample(sr, 16000)(wav_ref)
    if wav_ref.shape[1] > 16000*4: wav_ref = wav_ref[:, :16000*4]
    inputs = wavlm_proc(wav_ref.squeeze(), return_tensors="pt", sampling_rate=16000).input_values.to(device)
    with torch.no_grad(): emb_ref = wavlm_model(inputs).embeddings

    print("\n" + "="*50)
    print("KẾT QUẢ PHÂN TÍCH CHI TIẾT")
    print("="*50)

    for fname in CANDIDATES:
        fpath = os.path.join(RESULT_DIR, fname)
        if not os.path.exists(fpath): continue
        
        print(f"\nMODEL: {fname}")
        print("-" * 30)
        
        # 1. Metrics
        # WavLM
        wav_cand, sr = torchaudio.load(fpath)
        if wav_cand.shape[0] > 1: wav_cand = torch.mean(wav_cand, dim=0, keepdim=True)
        if sr != 16000: wav_cand = torchaudio.transforms.Resample(sr, 16000)(wav_cand)
        if wav_cand.shape[1] > 16000*4: wav_cand = wav_cand[:, :16000*4]
        inputs = wavlm_proc(wav_cand.squeeze(), return_tensors="pt", sampling_rate=16000).input_values.to(device)
        with torch.no_grad(): emb_cand = wavlm_model(inputs).embeddings
        
        sim = cos_sim(emb_ref, emb_cand).item()
        
        # Whisper
        transcription = asr_model.transcribe(fpath, language="vi", fp16=False)["text"].strip()
        wer = calculate_wer(text_ref, transcription)
        cer = calculate_cer(text_ref, transcription)
        
        print(f"   ➤ Similarity (Độ giống giọng):  {sim:.4f}  (Càng cao càng tốt)")
        print(f"   ➤ WER (Sai từ):               {wer*100:.2f}%   (Càng thấp càng tốt)")
        print(f"   ➤ CER (Sai ký tự):            {cer*100:.2f}%   (Càng thấp càng tốt)")
        
        # 2. Diff Text
        print(f"So sánh văn bản:")
        print(f"      Gốc: {text_ref}")
        print(f"      Máy: {color_diff(text_ref, transcription)}")
        
        # 3. Vẽ biểu đồ
        img_path = os.path.join(OUTPUT_IMAGE_DIR, f"spec_{fname}.png")
        try:
            draw_spectrogram_comparison(REF_WAV, fpath, fname, img_path)
        except Exception as e:
            print(f"Không vẽ được biểu đồ: {e}")

    print("\nHOÀN TẤT! Kiểm tra folder 'bieu_do_bao_cao' để lấy ảnh dán vào slide.")