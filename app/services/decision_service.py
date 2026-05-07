from app.models import DecisionSummary


BATCH_RULES = [
    {'level': 1, 'drawdown_pct': -5, 'cash_ratio': 0.10},
    {'level': 2, 'drawdown_pct': -10, 'cash_ratio': 0.15},
    {'level': 3, 'drawdown_pct': -15, 'cash_ratio': 0.25},
    {'level': 4, 'drawdown_pct': -20, 'cash_ratio': 0.40},
]


def get_decision_summary(symbol: str, current_price: float, high_60d: float, ma60: float, base_budget: float = 100000.0, locked_batch_level: int = 0) -> DecisionSummary:
    drawdown_pct = ((current_price / high_60d) - 1) * 100 if high_60d else 0
    bias = ((current_price / ma60) - 1) * 100 if ma60 else 0

    trend_status = 'ABOVE_MA60' if current_price >= ma60 else 'BELOW_MA60'
    market_status = 'NORMAL_PULLBACK'
    action = 'WAIT'
    reason = '位於強勢區，等待回檔'
    triggered = None
    suggested = 0.0

    if current_price > ma60 * 1.02 or bias > 8:
        action = 'WAIT'
        market_status = 'STRONG_ZONE'
    else:
        for rule in BATCH_RULES:
            if drawdown_pct <= rule['drawdown_pct'] and rule['level'] > locked_batch_level:
                triggered = rule['level']
                suggested = base_budget * rule['cash_ratio']
                action = f"BUY_BATCH_{triggered}"
                reason = f"達到第{triggered}批回檔"
                break

    return DecisionSummary(
        symbol=symbol,
        current_price=current_price,
        high_60d=high_60d,
        ma60=ma60,
        drawdown_pct=round(drawdown_pct, 2),
        bias_ma60_pct=round(bias, 2),
        trend_status=trend_status,
        market_status=market_status,
        triggered_batch_level=triggered,
        recommended_action=action,
        suggested_amount=round(suggested, 2),
        reason=reason,
    )
