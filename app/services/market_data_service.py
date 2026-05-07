from datetime import datetime

import httpx

from app.config import settings

TWSE_SOURCE = 'TWSE_REALTIME'
FINMIND_API_URL = 'https://api.finmindtrade.com/api/v4/data'


def fetch_twse_realtime_price(symbol: str) -> dict | None:
    """Fetch realtime TWSE quote. Returns None on any failure."""
    url = f"https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_{symbol}.tw"

    try:
        with httpx.Client(timeout=5) as client:
            response = client.get(url)
            response.raise_for_status()
            payload = response.json()

        msg_array = payload.get('msgArray') or []
        if not msg_array:
            return None

        latest = msg_array[0]
        raw_price = latest.get('z')
        if not raw_price or raw_price == '-':
            return None

        return {
            'symbol': symbol,
            'price': float(raw_price),
            'source': TWSE_SOURCE,
            'price_date': datetime.utcnow().strftime('%Y-%m-%d'),
        }
    except Exception:
        return None


def _fetch_finmind_dataset(symbol: str, dataset: str, days: int) -> list[dict]:
    end_date = datetime.utcnow().date()
    start_date = end_date.fromordinal(end_date.toordinal() - max(days * 2, 180))

    params = {
        'dataset': dataset,
        'data_id': symbol,
        'start_date': start_date.isoformat(),
        'end_date': end_date.isoformat(),
        'token': settings.finmind_token,
    }

    try:
        with httpx.Client(timeout=10) as client:
            response = client.get(FINMIND_API_URL, params=params)
            response.raise_for_status()
            payload = response.json()
    except Exception:
        return []

    data = payload.get('data') or []
    normalized: list[dict] = []
    for row in data:
        close_price = row.get('close')
        date = row.get('date')
        if close_price is None or not date:
            continue
        try:
            normalized.append(
                {
                    'symbol': symbol,
                    'price': float(close_price),
                    'source': dataset,
                    'price_date': str(date),
                }
            )
        except (TypeError, ValueError):
            continue

    normalized.sort(key=lambda item: item['price_date'])
    return normalized[-days:]


def fetch_finmind_daily_prices(symbol: str, days: int = 120) -> list[dict]:
    """Fetch daily close prices from FinMind with dataset fallback."""
    if days <= 0:
        return []

    primary = _fetch_finmind_dataset(symbol=symbol, dataset='TaiwanStockPriceAdj', days=days)
    if len(primary) >= days:
        return primary

    fallback = _fetch_finmind_dataset(symbol=symbol, dataset='TaiwanStockPrice', days=days)
    return fallback if fallback else primary
