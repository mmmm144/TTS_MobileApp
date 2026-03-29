# 🎙️ VN-TTS: Vietnamese Text-to-Speech Mobile App with XTTS-v2

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PyTorch](https://img.shields.io/badge/PyTorch-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white)

A comprehensive Vietnamese Text-to-Speech (TTS) system featuring a fine-tuned **Coqui XTTS-v2** model and a cross-platform mobile application built with **Flutter** and **FastAPI**. 

This system achieves highly natural Vietnamese voice synthesis with cross-lingual voice cloning capabilities, allowing the generation of high-quality speech from text using only a 3-6 second reference audio clip.

## ✨ Key Features

*   **Advanced Vietnamese TTS:** Produces highly accurate Vietnamese speech with natural prosody, tone, and pausing.
*   **Zero-Shot Voice Cloning:** Clone any voice (Cross-lingual support) using just a short 3-6 second reference audio file.
*   **Optimized Fine-Tuning:** The underlying XTTS-v2 model was fine-tuned on a high-quality 25-hour Vietnamese dataset, significantly reducing Character Error Rate (CER) and hallucination issues compared to base models.
*   **Scalable Client-Server Architecture:** Heavy AI inference is decoupled into a dedicated backend, ensuring smooth mobile performance.
*   **Clean Architecture Mobile App:** Flutter frontend designed for maintainability, smooth state management, and an excellent user experience.

## 🏗️ Technical Stack

This project is separated into a robust backend for heavy AI inference and a lightweight mobile frontend:

*   **AI / Machine Learning Engine:**
    *   **Model:** Coqui XTTS-v2 (Fine-tuned for Vietnamese).
    *   **Techniques used:** Discrete Variational Autoencoder (DVAE) tuning, GPT decoder fine-tuning, Gradient accumulation, and Custom Vocabulary Expansion.
    *   **Evaluation Metrics:** OpenAI Whisper for ASR (WER/CER evaluation) and Microsoft WavLM for Cosine Similarity.
*   **Backend Server:** 
    *   **Framework:** FastAPI (Python 3.10)
    *   Provides RESTful API endpoints for health checks, retrieving available voice IDs, and performing text-to-WAV generation.
*   **Mobile Client (Frontend):** 
    *   **Framework:** Flutter (Clean Architecture)
    *   **Libraries:** `just_audio` (audio playback), `provider` (state management), `http` (network requests).

## 🚀 Getting Started

### 1. Backend Setup

The backend requires Python 3.10 and a dedicated environment due to specific Machine Learning library dependencies.

```bash
# Clone the repository
git clone https://github.com/mmmm144/TTS_MobileApp.git
cd TTS_MobileApp

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies (requires system configuration for PyTorch)
pip install torch torchaudio torchvision
pip install TTS transformers huggingface_hub

# Run the FastAPI server
python main.py
```
*(Note: To test with a physical mobile device, expose the local server using tunneling tools like `ngrok`).*

### 2. Mobile App Setup (Flutter)

1. Navigate to the frontend directory: `./Code/Frontend (Flutter)/`.
2. Update the backend connection URL:
   * Open `lib/config/api_config.dart`.
   * Replace `baseUrl` with your active backend URL (e.g., your `ngrok` URL).
3. Install Flutter dependencies and run the app:
```bash
flutter pub get
flutter run
```
*Alternatively, you can deploy the pre-built APK available in `Dist/app-release.apk` directly to an Android device for testing.*

## 📊 Model Performance

During our automated evaluation pipeline, the fine-tuned model showcased remarkable improvements over community and baseline models:

| Model | Speaker Similarity | WER | CER |
| :--- | :---: | :---: | :---: |
| Meta MMS (Baseline) | 0.7127 | 20.00% | 12.24% |
| Our Fine-tuned XTTS-v2 | **0.9060** | **30.00%** | **10.20%** |

*Our model significantly handles local dialects and compound words efficiently while maintaining a high Mean Opinion Score (MOS) of 4.5/5.0 for Naturalness and Intelligibility.*

## 📁 Repository Structure

*   `Code/Frontend (Flutter)/`: The complete Flutter mobile application source code.
*   `Dist/`: Pre-compiled binaries and demo material (e.g., `app-release.apk`, `demo-ytb.txt`).
*   `Report/`: Technical documentation detailing the research, dataset preparation, fine-tuning pipeline, and evaluation methodologies (`report.pdf`).
