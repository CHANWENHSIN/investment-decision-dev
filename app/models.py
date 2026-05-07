from pydantic import BaseModel


class DecisionSummary(BaseModel):
    symbol: str
    current_price: float
    high_60d: float
    ma60: float
    drawdown_pct: float
    bias_ma60_pct: float
    trend_status: str
    market_status: str
    triggered_batch_level: int | None
    recommended_action: str
    suggested_amount: float
    reason: str


class MarkExecutedRequest(BaseModel):
    symbol: str
    batch_level: int
    amount: float
