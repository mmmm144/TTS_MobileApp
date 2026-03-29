import os
import torch
import json
import scipy.io.wavfile
import numpy as np
import multiprocessing
from huggingface_hub import snapshot_download

INPUT_FILE  = "text.txt"
REF_WAV     = "01_0029_s29.wav"
OUTPUT_DIR  = "ket_qua_so_sanh_meta"
MODELS_DIR  = "models_meta"

MODELS = [
    {"type": "xtts", "name": "1_AnhNH_Community",  "repo": "anhnh2002/vnTTS"},
    
    {"type": "xtts", "name": "2_Nhat1106_finetuned", "repo": "Nhat1106/xtts-vietnamese"},
    
    {"type": "meta", "name": "3_Meta_MMS_Base",    "repo": "facebook/mms-tts-vie"}
]

def run_xtts(model_info, text, ref_wav, out_path, device):
    """Chạy model XTTS (Coqui)"""
    from TTS.api import TTS
    print(f"   [XTTS] Đang tải {model_info['name']}...")
    
    path = snapshot_download(repo_id=model_info['repo'], local_dir=f"{MODELS_DIR}/{model_info['name']}")
    
    tts = TTS(model_path=path, config_path=f"{path}/config.json", progress_bar=False, gpu=False).to(device)
    
    print(f"Hack mode: language='en' (Model sẽ tự nói tiếng Việt)")
    tts.tts_to_file(text=text, speaker_wav=ref_wav, language="en", file_path=out_path)

def run_meta(model_info, text, out_path, device):
    """Chạy model Meta MMS (HuggingFace)"""
    from transformers import VitsModel, AutoTokenizer
    print(f"   [META] Đang tải {model_info['name']}...")
    
    model = VitsModel.from_pretrained(model_info['repo']).to(device)
    tokenizer = AutoTokenizer.from_pretrained(model_info['repo'])
    
    inputs = tokenizer(text, return_tensors="pt").to(device)
    with torch.no_grad():
        output = model(**inputs).waveform
    
    output_np = output.cpu().numpy().squeeze()
    scipy.io.wavfile.write(out_path, model.config.sampling_rate, output_np)
def worker(model_info, text, ref_wav, out_path, device):
    try:
        if model_info['type'] == 'xtts':
            run_xtts(model_info, text, ref_wav, out_path, device)
        elif model_info['type'] == 'meta':
            run_meta(model_info, text, out_path, device)
        print(f"HOÀN TẤT: {out_path}")
    except Exception as e:
        print(f"LỖI {model_info['name']}: {e}")
        import traceback; traceback.print_exc()

if __name__ == "__main__":
    os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"
    multiprocessing.set_start_method('spawn', force=True)
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    
    if not os.path.exists(INPUT_FILE): print("Thiếu text.txt"); exit()
    with open(INPUT_FILE, "r", encoding="utf-8") as f: text = f.read().strip()
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"START BENCHMARK (Device: {device})")
    print(f"   Text: {text}")

    for m in MODELS:
        outfile = os.path.join(OUTPUT_DIR, f"{m['name']}.wav")
        # Chạy từng process để tránh xung đột RAM/VRAM
        p = multiprocessing.Process(target=worker, args=(m, text, REF_WAV, outfile, device))
        p.start()
        p.join()

    print(f"\nĐÃ CÓ KẾT QUẢ TẠI: {OUTPUT_DIR}")