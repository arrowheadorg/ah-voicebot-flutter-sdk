import base64
import json
import os
import uuid
from typing import Any, Dict, Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI()

AH_API_URL = os.environ["AH_API_URL"].strip()
AH_API_TOKEN = os.environ["AH_API_TOKEN"].strip()
DOMAIN_ID = os.environ["DOMAIN_ID"].strip()
CAMPAIGN_ID = os.environ["CAMPAIGN_ID"].strip()


class CreateRoomDetailsRequest(BaseModel):
    customer_full_name: Optional[str] = None
    external_customer_id: str
    external_schedule_id: str
    input_variables: Optional[Dict[str, Any]] = None
    encrypted_customer_full_name: Optional[str] = None
    is_customer_data_encrypted: bool = False
    encryption_secret_name: str = "default"


class CreateRoomDetailsResponse(BaseModel):
    data: str = Field(description="Base64url-encoded room details")


@app.post("/room-details", response_model=CreateRoomDetailsResponse)
async def room_details(body: Optional[CreateRoomDetailsRequest] = None):
    if body is None:
        body = CreateRoomDetailsRequest(
            external_customer_id=f"flutter-user-{uuid.uuid4().hex[:8]}",
            external_schedule_id=f"flutter-session-{uuid.uuid4().hex[:8]}",
            input_variables={"lead_source": "app"},
        )

    url = f"{AH_API_URL}/api/v1/public/domain/{DOMAIN_ID}/campaign/{CAMPAIGN_ID}/room-details"
    headers = {"Authorization": f"Bearer {AH_API_TOKEN}"}

    payload = body.model_dump()
    print(f"POST {url}")
    print(f"Body: {payload}")

    async with httpx.AsyncClient() as client:
        resp = await client.post(url, headers=headers, json=payload)

    print(f"Response {resp.status_code}: {resp.text}")

    if resp.status_code != 200:
        raise HTTPException(status_code=resp.status_code, detail=resp.text)

    data = resp.json()
    encoded = base64.urlsafe_b64encode(
        json.dumps({"room_url": data["room_url"], "token": data["token"]}).encode()
    ).decode()
    return {"data": encoded}
