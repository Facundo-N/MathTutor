"""
backend/scripts/download_kokoro_models.py
Script de descarga automática de los modelos de Kokoro TTS.
Ejecutar UNA SOLA VEZ antes de correr el backend por primera vez.

Uso:
    python backend/scripts/download_kokoro_models.py
"""
import urllib.request
import os
from pathlib import Path

MODELS_DIR = Path(__file__).parent.parent / "models"
MODELS_DIR.mkdir(exist_ok=True)

FILES = {
    "kokoro-v1.0.onnx": "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx",
    "voices-v1.0.bin":  "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin",
}


def download(name: str, url: str):
    dest = MODELS_DIR / name
    if dest.exists():
        print(f"✅ {name} ya existe ({dest.stat().st_size // 1024 // 1024} MB), saltando.")
        return

    print(f"⬇️  Descargando {name}...")
    print(f"   URL: {url}")

    def progress(block_num, block_size, total_size):
        downloaded = block_num * block_size
        if total_size > 0:
            pct = min(100, downloaded * 100 // total_size)
            mb = downloaded / 1024 / 1024
            total_mb = total_size / 1024 / 1024
            print(f"\r   {pct}% — {mb:.1f}/{total_mb:.1f} MB", end="", flush=True)

    urllib.request.urlretrieve(url, dest, progress)
    print(f"\n✅ {name} descargado ({dest.stat().st_size // 1024 // 1024} MB)")


if __name__ == "__main__":
    print("=" * 60)
    print("🎤 Descargando modelos de Kokoro TTS v1.0")
    print(f"   Destino: {MODELS_DIR}")
    print("=" * 60)

    for name, url in FILES.items():
        download(name, url)

    print("\n🎉 Modelos listos. Ahora podés iniciar el backend.")
    print("   Voz configurada: ef_dora (español femenino)")
