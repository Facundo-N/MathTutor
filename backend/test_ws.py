import asyncio
import websockets
import json

async def test_ws():
    uri = 'ws://127.0.0.1:8000/ws/chat/test_user'
    try:
        print("Connecting...")
        async with websockets.connect(uri) as websocket:
            print('Connected')
            message = {'type': 'message', 'content': '[SYSTEM_INIT_THEORY]', 'user_id': 'test_user'}
            await websocket.send(json.dumps(message))
            print('Sent')
            response = await websocket.recv()
            print('Received:', response)
    except Exception as e:
        print('Error:', e)

asyncio.run(test_ws())
