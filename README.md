# investment-decision-dev

Investment Decision Center V1 skeleton built with FastAPI + Jinja2.

## Quick start

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Environment variables

- `SUPABASE_URL`
- `SUPABASE_KEY`
- `FINMIND_TOKEN`

## Implemented in this commit

- V1 API stubs
  - `GET /decision/{symbol}`
  - `POST /strategy/mark-executed`
  - `POST /price/refresh/{symbol}`
- Core decision function: `get_decision_summary`
- Market price function: `get_market_price` with TWSE + fallback
- Basic Tailwind UI dashboard
