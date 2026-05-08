import os

from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.models import MarkExecutedRequest
from app.services.decision_service import get_decision_summary

app = FastAPI(title='Investment Decision Center')
templates = Jinja2Templates(directory='app/templates')

REQUIRED_ENV_VARS = ['SUPABASE_URL', 'SUPABASE_KEY', 'FINMIND_TOKEN']


def get_missing_env_vars() -> list[str]:
    return [name for name in REQUIRED_ENV_VARS if not os.getenv(name)]


@app.get('/health')
def health_check():
    missing = get_missing_env_vars()
    if missing:
        return {
            'status': 'error',
            'service': 'investment-decision-center',
            'error': 'Missing required environment variables.',
            'missing': missing,
        }

    return {'status': 'ok', 'service': 'investment-decision-center'}


@app.get('/decision/{symbol}')
def decision(symbol: str):
    # TODO: replace demo data with Supabase price_cache query.
    summary = get_decision_summary(symbol=symbol, current_price=185, high_60d=198, ma60=178)
    return summary.model_dump()


@app.post('/strategy/mark-executed')
def mark_executed(payload: MarkExecutedRequest):
    # TODO: write into allocation_log and update strategy_state in Supabase.
    return {'status': 'ok', 'symbol': payload.symbol, 'batch_level': payload.batch_level, 'amount': payload.amount}


@app.post('/price/refresh/{symbol}')
def refresh_price(symbol: str):
    # TODO: implement FinMind refresh and persist into price_cache.
    return {'status': 'queued', 'symbol': symbol}


@app.get('/', response_class=HTMLResponse)
def home(request: Request):
    sample = get_decision_summary(symbol='0050', current_price=185, high_60d=198, ma60=178)
    return templates.TemplateResponse('index.html', {'request': request, 'summary': sample.model_dump()})
