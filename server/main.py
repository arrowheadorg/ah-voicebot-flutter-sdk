import os
import uuid
from typing import Any, Dict, Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

AH_API_URL = os.environ["AH_API_URL"].strip()
AH_API_TOKEN = os.environ["AH_API_TOKEN"].strip()
DOMAIN_ID = os.environ["DOMAIN_ID"].strip()
CAMPAIGN_ID = os.environ["CAMPAIGN_ID"].strip()


class InitiateCallRequest(BaseModel):
    customer_full_name: Optional[str] = None
    external_customer_id: str
    external_schedule_id: str
    input_variables: Optional[Dict[str, Any]] = None
    encrypted_customer_full_name: Optional[str] = None
    is_customer_data_encrypted: bool = False
    encryption_secret_name: str = "default"


class InitiateCallResponse(BaseModel):
    data: str = Field(description="Call session payload to pass to the SDK")


class EventRequest(BaseModel):
    external_customer_id: str
    event_name: str
    event_body: Optional[Dict[str, Any]] = None


class ConnectionManager:
    def __init__(self):
        # topic (external_customer_id) -> connections subscribed to it
        self.topics: Dict[str, list[WebSocket]] = {}

    async def connect(self, topic: str, websocket: WebSocket):
        await websocket.accept()
        self.topics.setdefault(topic, []).append(websocket)

    def disconnect(self, topic: str, websocket: WebSocket):
        connections = self.topics.get(topic)
        if not connections:
            return
        if websocket in connections:
            connections.remove(websocket)
        if not connections:
            self.topics.pop(topic, None)

    async def publish(self, topic: str, message: Dict[str, Any]) -> int:
        connections = self.topics.get(topic, [])
        disconnected = []
        delivered = 0
        for connection in connections:
            try:
                await connection.send_json(message)
                delivered += 1
            except Exception:
                disconnected.append(connection)
        for connection in disconnected:
            self.disconnect(topic, connection)
        return delivered


manager = ConnectionManager()


@app.websocket("/ws/{external_customer_id}")
async def websocket_endpoint(websocket: WebSocket, external_customer_id: str):
    await manager.connect(external_customer_id, websocket)
    try:
        while True:
            # Keep the connection alive; clients are receive-only.
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(external_customer_id, websocket)


@app.post("/event")
async def event(body: EventRequest):
    payload = body.model_dump()
    print(f"Received event: {payload}")
    delivered = await manager.publish(body.external_customer_id, payload)
    return {
        "status": "ok",
        "event_name": body.event_name,
        "external_customer_id": body.external_customer_id,
        "delivered_to": delivered,
    }


@app.post("/initiate-call", response_model=InitiateCallResponse)
async def initiate_call(body: Optional[InitiateCallRequest] = None):
    if body is None:
        body = InitiateCallRequest(
            external_customer_id=f"flutter-user-{uuid.uuid4().hex[:8]}",
            external_schedule_id=f"flutter-session-{uuid.uuid4().hex[:8]}",
            input_variables={"lead_source": "app"},
        )

    url = f"{AH_API_URL}/api/v2/public/domain/{DOMAIN_ID}/campaign/{CAMPAIGN_ID}/initiate-call"
    headers = {"Authorization": f"Bearer {AH_API_TOKEN}"}

    payload = body.model_dump()
    print(f"POST {url}")
    print(f"Body: {payload}")

    async with httpx.AsyncClient() as client:
        resp = await client.post(url, headers=headers, json=payload)

    print(f"Response {resp.status_code}: {resp.text}")

    if resp.status_code != 200:
        raise HTTPException(status_code=resp.status_code, detail=resp.text)

    return resp.json()
