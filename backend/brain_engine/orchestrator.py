# backend/brain_engine/orchestrator.py
import os
from .ollama_client import OllamaAgent
from .memory import ProjectMemory
from .config import PROJECT_ROOT

class BrainOrchestrator:
    def __init__(self):
        self.agent = OllamaAgent()
        self.memory = ProjectMemory()
        self.bridge_path = PROJECT_ROOT / "bridge_interaction.md"

    def execute_task(self, task_description):
        """
        Flujo de trabajo:
        1. Buscar contexto relevante en el proyecto.
        2. Construir el prompt con la memoria del proyecto.
        3. Consultar a Gemma (Ollama).
        4. Actualizar el puente de comunicación.
        """
        print(f"🛠️ Procesando tarea: {task_description}")
        
        # 1. Obtener contexto
        context = self.memory.get_context_for_task(task_description)
        repo_summary = self.memory.get_repo_summary()
        
        # 2. Construir Prompt
        system_prompt = f"""
        Eres un Ingeniero de Software experto especializado en Dart, Flutter y Python.
        Tienes acceso a la estructura del proyecto actual para proporcionar respuestas precisas.
        
        {repo_summary}
        
        Reglas:
        - Siempre usa el contexto proporcionado para fundamentar tus respuestas.
        - Si no conoces un archivo, admítelo y sugiere dónde buscar.
        - Mantén un tono profesional y colaborativo.
        """
        
        user_prompt = f"""
        TAREA: {task_description}
        
        {context}
        
        Por favor, resuelve la tarea basándote en el código anterior.
        """
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
        
        # 3. Llamar a Ollama
        print("🤖 Consultando a Gemma 4 (Ollama)...")
        response_content = ""
        response_stream = self.agent.chat(messages)
        
        if response_stream:
            for chunk in response_stream:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    print(content, end="", flush=True)
                    response_content += content
            print("\n")
        else:
            response_content = "Fallo en la comunicación con el agente local."

        # 4. Actualizar Bridge
        self._update_bridge(task_description, response_content)
        
        return response_content

    def _update_bridge(self, task, result):
        """Anota la interacción en bridge_interaction.md"""
        try:
            with open(self.bridge_path, "a", encoding="utf-8") as f:
                f.write(f"\n> **Antigravity**: Tarea enviada -> {task}\n")
                f.write(f"> **Gemma (Ollama)**: {result[:200]}... (ver logs para detalles completos)\n")
        except Exception as e:
            print(f"⚠️ No se pudo actualizar el puente: {e}")

if __name__ == "__main__":
    # Test inicial
    orchestrator = BrainOrchestrator()
    # Primero indexamos si es necesario
    orchestrator.memory.build_repo_map()
    # Ejecutamos tarea de prueba
    orchestrator.execute_task("Explica brevemente cómo está estructurado el backend en base a lo que ves.")
