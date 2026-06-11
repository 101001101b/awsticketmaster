from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID, uuid4


@dataclass
class BuyRequest:
    request_id: UUID = field(default_factory=uuid4)
    event_id: int = 1
    seat_id: int | None = None
    mode: str = "numbered"
    enqueue_ts: datetime | None = None

    @classmethod
    def from_dict(cls, data: dict):
        return cls(
            request_id=UUID(data.get("request_id", str(uuid4()))),
            event_id=data.get("event_id", 1),
            seat_id=data.get("seat_id"),
            mode=data.get("mode", "numbered"),
            enqueue_ts=datetime.fromisoformat(data["enqueue_ts"]) if "enqueue_ts" in data else None,
        )
