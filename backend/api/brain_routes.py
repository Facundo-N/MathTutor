# backend/api/brain_routes.py
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional, Any
from brain_engine.orchestrator import BrainOrchestrator
from brain_engine.memory import ProjectMemory

router = APIRouter(prefix="/api/brain", tags=["brain-engine"])
orchestrator = BrainOrchestrator()
memory = ProjectMemory()

class BrainQueryRequest(BaseModel):
    query: str
    user_id: Optional[str] = "admin"

class BrainQueryResponse(BaseModel):
    task: str
    response: str
    context_used: bool

@router.post("/query", response_model=BrainQueryResponse)
async def query_brain(request: BrainQueryRequest):
    """
    Consulta al motor de IA sobre el proyecto actual.
    Gemma (Ollama) utilizará la memoria extendida para responder.
    """
    try:
        response = orchestrator.execute_task(request.query)
        return BrainQueryResponse(
            task=request.query,
            response=response,
            context_used=True
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en el Brain Engine: {str(e)}")

@router.post("/index")
async def trigger_indexing(background_tasks: BackgroundTasks):
    """
    Inicia el proceso de re-indexación del proyecto en segundo plano.
    """
    background_tasks.add_task(memory.build_repo_map)
    return {"message": "Indexación iniciada en segundo plano."}

@router.get("/stats")
async def get_brain_stats():
    """
    Obtiene estadísticas básicas del índice de memoria.
    """
    try:
        # Intentar cargar índice si no está en memoria
        if not memory.index:
            import json
            from brain_engine.config import INDEX_FILE
            if INDEX_FILE.exists():
                with open(INDEX_FILE, "r") as f:
                    memory.index = json.load(f)
        
        file_count = len(memory.index.get("files", []))
        return {
            "status": "active" if file_count > 0 else "unindexed",
            "indexed_files": file_count,
            "project_name": memory.index.get("project_name", "unknown")
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}
