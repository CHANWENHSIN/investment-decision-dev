-- Decision center tables migration

-- 1) investment_targets
CREATE TABLE IF NOT EXISTS investment_targets (
    id BIGSERIAL PRIMARY KEY,
    symbol TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2) price_cache
CREATE TABLE IF NOT EXISTS price_cache (
    id BIGSERIAL PRIMARY KEY,
    symbol TEXT NOT NULL,
    price NUMERIC(18,6) NOT NULL,
    price_date DATE,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT price_cache_symbol_unique UNIQUE (symbol)
);

-- 3) strategy_batches
CREATE TABLE IF NOT EXISTS strategy_batches (
    id BIGSERIAL PRIMARY KEY,
    batch_no INTEGER NOT NULL UNIQUE,
    drawdown_pct NUMERIC(6,2) NOT NULL,
    allocation_pct NUMERIC(6,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4) strategy_state
CREATE TABLE IF NOT EXISTS strategy_state (
    id BIGSERIAL PRIMARY KEY,
    target_id BIGINT NOT NULL REFERENCES investment_targets(id) ON DELETE CASCADE,
    current_batch_no INTEGER NOT NULL DEFAULT 0,
    avg_cost NUMERIC(18,6),
    total_quantity NUMERIC(18,6) NOT NULL DEFAULT 0,
    total_invested NUMERIC(18,6) NOT NULL DEFAULT 0,
    last_action_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT strategy_state_target_unique UNIQUE (target_id)
);

-- 5) allocation_log
CREATE TABLE IF NOT EXISTS allocation_log (
    id BIGSERIAL PRIMARY KEY,
    target_id BIGINT NOT NULL REFERENCES investment_targets(id) ON DELETE CASCADE,
    batch_id BIGINT REFERENCES strategy_batches(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    trigger_price NUMERIC(18,6),
    execution_price NUMERIC(18,6),
    quantity NUMERIC(18,6),
    invested_amount NUMERIC(18,6),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Keep updated_at in sync automatically.
CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_investment_targets_updated_at
BEFORE UPDATE ON investment_targets
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_price_cache_updated_at
BEFORE UPDATE ON price_cache
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_strategy_batches_updated_at
BEFORE UPDATE ON strategy_batches
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_strategy_state_updated_at
BEFORE UPDATE ON strategy_state
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_allocation_log_updated_at
BEFORE UPDATE ON allocation_log
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_timestamp();

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_price_cache_symbol ON price_cache(symbol);
CREATE INDEX IF NOT EXISTS idx_strategy_state_target_id ON strategy_state(target_id);
CREATE INDEX IF NOT EXISTS idx_allocation_log_target_id ON allocation_log(target_id);
CREATE INDEX IF NOT EXISTS idx_allocation_log_created_at ON allocation_log(created_at);

-- Seed strategy batches
INSERT INTO strategy_batches (batch_no, drawdown_pct, allocation_pct)
VALUES
    (1, -5.00, 10.00),
    (2, -10.00, 15.00),
    (3, -15.00, 25.00),
    (4, -20.00, 40.00)
ON CONFLICT (batch_no) DO UPDATE
SET
    drawdown_pct = EXCLUDED.drawdown_pct,
    allocation_pct = EXCLUDED.allocation_pct,
    updated_at = NOW();

-- Seed default investment targets
INSERT INTO investment_targets (symbol)
VALUES
    ('0050'),
    ('2330'),
    ('00881'),
    ('0056'),
    ('00919'),
    ('VOO')
ON CONFLICT (symbol) DO NOTHING;
