# backend/routes/websocket.py (NUEVO ARCHIVO)

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
import json
import asyncio

router = APIRouter(prefix="/ws", tags=["WebSocket"])

# Conexiones activas: {user_id: WebSocket}
active_connections: Dict[str, WebSocket] = {}

@router.websocket("/tutor/{user_id}")
async def websocket_tutor(websocket: WebSocket, user_id: str):
    """
    WebSocket para enviar TutorActions en tiempo real
    """
    await websocket.accept()
    active_connections[user_id] = websocket
    
    print(f"✅ WebSocket connected: {user_id}")
    
    try:
        while True:
            # Escuchar mensajes del frontend (opcional)
            data = await websocket.receive_text()
            message = json.loads(data)
            
            print(f"📩 Received from {user_id}: {message}")
            
            # Aquí podrías procesar señales en tiempo real
            # y enviar TutorAction inmediatamente
            
    except WebSocketDisconnect:
        del active_connections[user_id]
        print(f"❌ WebSocket disconnected: {user_id}")

# Función helper para enviar TutorAction
async def send_tutor_action(user_id: str, action: Dict):
    """
    Envía una TutorAction al frontend si está conectado
    """
    if user_id in active_connections:
        await active_connections[user_id].send_text(json.dumps(action))
        print(f"📤 Sent to {user_id}: {action['type']}")
    else:
        print(f"⚠️ User {user_id} not connected")
