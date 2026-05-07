from datetime import datetime

import httpx


def get_twse_price(symbol: str) -> float | None:
    # NOTE: TWSE endpoint placeholder for V1; parse based on real payload in Phase 2.
    url = f"https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_{symbol}.tw"
    try:
        with httpx.Client(timeout=5) as client:
            res = client.get(url)
            res.raise_for_status()
            payload = res.json()
            msg_array = payload.get('msgArray') or []
            if not msg_array:
                return None
            z = msg_array[0].get('z')
            return float(z) if z and z != '-' else None
    except Exception:
        return None


def get_market_price(symbol: str, cache_row: dict | None = None, fallback_price: float = 0.0) -> float:
    price = get_twse_price(symbol)
    if price is not None:
        return price

    if cache_row and cache_row.get('current_price'):
        return float(cache_row['current_price'])

    return fallback_price


def now_iso() -> str:
    return datetime.utcnow().isoformat()
