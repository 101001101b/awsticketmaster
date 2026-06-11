import os
from dataclasses import dataclass, field


def _env_float(name: str, default: float) -> float:
    val = os.environ.get(name)
    return float(val) if val else default


def _env_int(name: str, default: int) -> int:
    val = os.environ.get(name)
    return int(val) if val else default


@dataclass
class PhaseConfig:
    low_rate: float = field(default_factory=lambda: _env_float("LOAD_LOW_RATE", 50.0))
    high_rate: float = field(default_factory=lambda: _env_float("LOAD_HIGH_RATE", 500.0))
    spike_rate: float = field(default_factory=lambda: _env_float("LOAD_SPIKE_RATE", 2500.0))
    t1_low_s: int = field(default_factory=lambda: _env_int("LOAD_T1_LOW_S", 60))
    t2_ramp_s: int = field(default_factory=lambda: _env_int("LOAD_T2_RAMP_S", 60))
    t3_spike_s: int = field(default_factory=lambda: _env_int("LOAD_T3_SPIKE_S", 30))
    t4_sustained_s: int = field(default_factory=lambda: _env_int("LOAD_T4_SUSTAINED_S", 120))
    t5_cooldown_s: int = field(default_factory=lambda: _env_int("LOAD_T5_COOLDOWN_S", 60))
    spike_bursts: int = field(default_factory=lambda: _env_int("LOAD_SPIKE_BURSTS", 3))


@dataclass
class LoadConfig:
    rabbitmq_host: str = field(default_factory=lambda: os.environ.get("RABBITMQ_HOST", "localhost"))
    rabbitmq_port: int = field(default_factory=lambda: int(os.environ.get("RABBITMQ_PORT", "5672")))
    rabbitmq_user: str = field(default_factory=lambda: os.environ.get("RABBITMQ_USER", "guest"))
    rabbitmq_pass: str = field(default_factory=lambda: os.environ.get("RABBITMQ_PASS", "guest"))
    exchange: str = "tickets"
    routing_key: str = "buy"

    mode: str = field(default_factory=lambda: os.environ.get("LOAD_MODE", "numbered"))
    hotspot_pct_seats: float = field(default_factory=lambda: _env_float("LOAD_HOTSPOT_PCT_SEATS", 5.0))
    hotspot_pct_traffic: float = field(default_factory=lambda: _env_float("LOAD_HOTSPOT_PCT_TRAFFIC", 80.0))
    total_seats: int = field(default_factory=lambda: _env_int("LOAD_TOTAL_SEATS", 100000))
    total_capacity: int = field(default_factory=lambda: _env_int("LOAD_TOTAL_CAPACITY", 100000))

    phase: PhaseConfig = field(default_factory=PhaseConfig)
