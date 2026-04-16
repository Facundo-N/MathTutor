# backend/brain_engine/memory.py
import os
import json
from pathlib import Path
from .config import PROJECT_ROOT, INDEX_EXTENSIONS, IGNORE_DIRS, INDEX_FILE

class ProjectMemory:
    def __init__(self):
        self.root = PROJECT_ROOT
        self.index = {}

    def build_repo_map(self):
        """
        Escanea el proyecto y crea una estructura simplificada para que el LLM
        entienda la jerarquía y el propósito de los archivos.
        """
        print(f"🔍 Indexando proyecto en {self.root}...")
        repo_map = []
        
        for p in self.root.rglob("*"):
            if any(ignore in str(p) for ignore in IGNORE_DIRS):
                continue
            
            if p.suffix in INDEX_EXTENSIONS:
                relative_path = p.relative_to(self.root)
                # Obtenemos un resumen rápido (primeras 5 líneas de comentarios/código)
                summary = ""
                try:
                    with open(p, "r", encoding="utf-8") as f:
                        lines = f.readlines()[:10]
                        summary = "".join([l for l in lines if l.strip()])
                except Exception:
                    summary = "(Error leyendo archivo)"
                
                repo_map.append({
                    "path": str(relative_path),
                    "summary": summary
                })
        
        self.index = {
            "project_name": self.root.name,
            "files": repo_map
        }
        
        # Guardar índice
        os.makedirs(INDEX_FILE.parent, exist_ok=True)
        with open(INDEX_FILE, "w", encoding="utf-8") as f:
            json.dump(self.index, f, indent=2)
        
        print(f"✅ Índice creado con {len(repo_map)} archivos.")

    def get_repo_summary(self):
        """
        Retorna un string que describe la estructura del proyecto.
        Ideal para inyectar en el 'system prompt'.
        """
        if not self.index:
            if INDEX_FILE.exists():
                with open(INDEX_FILE, "r") as f:
                    self.index = json.load(f)
            else:
                return "Proyecto no indexado."
        
        summary = "ESTRUCTURA DEL PROYECTO:\n"
        for file in self.index["files"]:
            summary += f"- {file['path']}\n"
        return summary

    def get_context_for_task(self, query):
        """
        Busca fragmentos de código relevantes basados en keywords.
        (En el futuro se puede mejorar con embeddings/ChromaDB).
        """
        if not self.index:
            self.build_repo_map()
            
        relevant_files = []
        query_words = query.lower().split()
        
        for file in self.index["files"]:
            score = 0
            for word in query_words:
                if word in file["path"].lower() or word in file["summary"].lower():
                    score += 1
            if score > 0:
                relevant_files.append((score, file["path"]))
        
        # Ordenar por relevancia
        relevant_files.sort(key=lambda x: x[0], reverse=True)
        
        # Leer el contenido completo de los 3 archivos más relevantes
        context = "CONTEXTO RELEVANTE:\n"
        for _, path in relevant_files[:3]:
            full_path = self.root / path
            try:
                with open(full_path, "r", encoding="utf-8") as f:
                    context += f"\n--- {path} ---\n"
                    context += f.read()
            except Exception:
                pass
                
        return context

if __name__ == "__main__":
    memory = ProjectMemory()
    memory.build_repo_map()
    print("\nResumen para el Prompt:")
    print(memory.get_repo_summary()[:500] + "...")
