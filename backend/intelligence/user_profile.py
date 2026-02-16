# backend/intelligence/user_profile.py (NUEVO ARCHIVO)

import chromadb
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional
from datetime import datetime
import json

class UserIntelligenceProfile:
    """
    Memoria vectorial personalizada con ChromaDB
    """
    
    def __init__(self):
        # ChromaDB client (persistente en disco)
        self.chroma_client = chromadb.PersistentClient(path="./chroma_db")
        
        # Colección para guardar interacciones exitosas
        self.collection = self.chroma_client.get_or_create_collection(
            name="user_profiles",
            metadata={"description": "Pedagogical memory for MathTutor"}
        )
        
        # Modelo de embeddings (ligero, 80MB)
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2')
    
    def store_successful_interaction(
        self,
        user_id: str,
        problem: Dict,
        solution_strategy: str,
        explanation_used: str,
        effectiveness_score: float,  # 0.0-1.0
        visual_style_used: str,
        scaffolding_level: float,
    ):
        """
        Guarda cada ÉXITO para reutilizarlo después
        """
        # Crear embedding del problema
        problem_text = f"{problem.get('type', '')} {problem.get('expression', '')} {problem.get('topic', '')}"
        embedding = self.embedder.encode(problem_text).tolist()
        
        # ID único para esta interacción
        interaction_id = f"{user_id}_{int(datetime.now().timestamp())}"
        
        # Almacenar en ChromaDB
        self.collection.add(
            embeddings=[embedding],
            documents=[explanation_used],
            metadatas=[{
                "user_id": user_id,
                "problem_type": problem.get('type', 'unknown'),
                "strategy": solution_strategy,
                "effectiveness": effectiveness_score,
                "timestamp": datetime.now().isoformat(),
                "visual_style_used": visual_style_used,
                "scaffolding_level": scaffolding_level,
            }],
            ids=[interaction_id]
        )
        
        print(f"✅ Stored success for {user_id}: {problem_text[:50]}...")
    
    def retrieve_similar_successes(
        self,
        user_id: str,
        current_problem: Dict,
        top_k: int = 3
    ) -> List[Dict]:
        """
        Busca éxitos pasados similares al problema actual
        """
        # Crear embedding del problema actual
        problem_text = f"{current_problem.get('type', '')} {current_problem.get('expression', '')} {current_problem.get('topic', '')}"
        query_embedding = self.embedder.encode(problem_text).tolist()
        
        # Búsqueda vectorial en ChromaDB
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
            where={"user_id": user_id}  # Solo del mismo usuario
        )
        
        # Si NO tiene historial propio, buscar de usuarios similares
        if not results['documents'][0]:
            print(f"⚠️ No history for {user_id}, searching similar users...")
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k,
                # Sin filtro de usuario
            )
        
        return results
    
    def store_failed_interaction(
        self,
        user_id: str,
        problem: Dict,
        failed_approach: str,
        reason: str
    ):
        """
        Guarda qué NO funcionó para evitarlo en el futuro
        """
        # Guardar en metadata como "effectiveness": 0.0
        problem_text = f"{problem.get('type', '')} {problem.get('expression', '')}"
        embedding = self.embedder.encode(problem_text).tolist()
        
        interaction_id = f"{user_id}_FAIL_{int(datetime.now().timestamp())}"
        
        self.collection.add(
            embeddings=[embedding],
            documents=[f"FAILED: {failed_approach}"],
            metadatas=[{
                "user_id": user_id,
                "problem_type": problem.get('type', 'unknown'),
                "strategy": failed_approach,
                "effectiveness": 0.0,  # MARCA DE FALLO
                "failure_reason": reason,
                "timestamp": datetime.now().isoformat(),
            }],
            ids=[interaction_id]
        )
        
        print(f"❌ Stored failure for {user_id}: {failed_approach}")
