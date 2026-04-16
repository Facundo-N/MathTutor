# backend/brain_engine/ollama_client.py
import os
from openai import OpenAI
from .config import OLLAMA_BASE_URL, OLLAMA_MODEL

class OllamaAgent:
    def __init__(self, model=OLLAMA_MODEL, base_url=OLLAMA_BASE_URL):
        self.model = model
        # Usamos el cliente de OpenAI compatible con Ollama
        self.client = OpenAI(
            base_url=base_url,
            api_key="ollama",  # Requerido pero ignorado por Ollama
        )

    def chat(self, messages, stream=True):
        """
        Envía una lista de mensajes al modelo de Ollama.
        """
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                stream=stream
            )
            return response
        except Exception as e:
            print(f"❌ Error comunicando con Ollama: {e}")
            return None

    def generate_simple(self, prompt):
        """
        Helper para una respuesta rápida sin streaming.
        """
        messages = [{"role": "user", "content": prompt}]
        response = self.chat(messages, stream=False)
        if response:
            return response.choices[0].message.content
        return "Error: No se pudo generar respuesta."

if __name__ == "__main__":
    # Test rápido de conectividad
    print(f"🚀 Probando conexión con {OLLAMA_MODEL}...")
    agent = OllamaAgent()
    resp = agent.generate_simple("Responde solo con la palabra 'OK' si me escuchas.")
    print(f"🤖 Respuesta: {resp}")
