-- Phase 2 hardening migration: make trigger creation idempotent and enforce expected seeds.

-- Ensure shared trigger function exists.
CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_investment_targets_updated_at') THEN
        CREATE TRIGGER trg_investment_targets_updated_at
        BEFORE UPDATE ON investment_targets
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_price_cache_updated_at') THEN
        CREATE TRIGGER trg_price_cache_updated_at
        BEFORE UPDATE ON price_cache
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_strategy_batches_updated_at') THEN
        CREATE TRIGGER trg_strategy_batches_updated_at
        BEFORE UPDATE ON strategy_batches
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_strategy_state_updated_at') THEN
        CREATE TRIGGER trg_strategy_state_updated_at
        BEFORE UPDATE ON strategy_state
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_allocation_log_updated_at') THEN
        CREATE TRIGGER trg_allocation_log_updated_at
        BEFORE UPDATE ON allocation_log
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;
END $$;

-- Ensure phase-required batch configuration exists.
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

-- Ensure phase-required investment targets exist.
INSERT INTO investment_targets (symbol)
VALUES
    ('0050'),
    ('2330'),
    ('00881'),
    ('0056'),
    ('00919'),
    ('VOO')
ON CONFLICT (symbol) DO NOTHING;
