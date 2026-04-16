# backend/scripts/bootstrap_brain.py
import sys
import os
from pathlib import Path

# Agregar raíz al path
sys.path.append(str(Path(__file__).parent.parent))

from brain_engine.memory import ProjectMemory
from brain_engine.ollama_client import OllamaAgent

def bootstrap():
    print("🧠 BOOTSTRAP: Inicializando Brain Engine...")
    
    # 1. Verificar Ollama
    print("📡 Verificando conexión con Ollama...")
    agent = OllamaAgent()
    test_resp = agent.generate_simple("Responde con 'LISTO' si me escuchas.")
    if "LISTO" in test_resp.upper() or len(test_resp) > 0:
        print("✅ Ollama está respondiendo correctamente.")
    else:
        print("❌ Error: Ollama no parece estar disponible. Asegúrate de que esté corriendo.")
        return

    # 2. Inicializar Memoria
    print("📂 Iniciando indexación del proyecto...")
    memory = ProjectMemory()
    memory.build_repo_map()
    print("✅ Indexación completada.")
    
    # 3. Prueba de concepto
    print("\n🤖 Realizando prueba de razonamiento...")
    from brain_engine.orchestrator import BrainOrchestrator
    orch = BrainOrchestrator()
    summary = orch.execute_task("¿Cuáles son los 3 archivos principales de este backend y qué hacen?")
    print("-" * 50)
    print("RESPUESTA INICIAL DE GEMMA:")
    print(summary)
    print("-" * 50)
    
    print("\n🚀 ¡SISTEMA LISTO PARA USAR!")
    print("Ya puedes usar el endpoint /api/brain/query desde Flutter.")

if __name__ == "__main__":
    bootstrap()
