-- Reference DDL for the Topfolio SaaS schema (schema: saas).
-- Reconstructed from information_schema: column names, types, and
-- nullability only. Constraints/indexes are NOT exported.
-- Row counts and quirks: see findings/data_dictionary.md.

-- saas.accounts: 1250 rows.
CREATE TABLE saas.accounts (
    account_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    account_type TEXT NOT NULL,
    industry TEXT,
    employee_count INTEGER,
    country TEXT,
    signup_date TIMESTAMP WITH TIME ZONE,
    acquisition_channel TEXT
);

-- saas.users: 2556 rows.
CREATE TABLE saas.users (
    user_id INTEGER NOT NULL,
    email TEXT,
    company_name TEXT,
    signup_date TIMESTAMP WITHOUT TIME ZONE,
    signup_source TEXT,
    plan_type TEXT,
    is_active INTEGER,
    last_login_date TIMESTAMP WITHOUT TIME ZONE,
    account_id BIGINT,
    role TEXT
);

-- saas.signups: 2556 rows.
CREATE TABLE saas.signups (
    user_id INTEGER,
    account_id BIGINT,
    signup_date TIMESTAMP WITHOUT TIME ZONE,
    signup_source TEXT
);

-- saas.plans: 8 rows.
CREATE TABLE saas.plans (
    plan_id INTEGER NOT NULL,
    plan_name TEXT NOT NULL,
    monthly_price NUMERIC NOT NULL,
    seat_limit INTEGER,
    billing_interval TEXT NOT NULL
);

-- saas.subscriptions: 2113 rows.
CREATE TABLE saas.subscriptions (
    subscription_id INTEGER NOT NULL,
    user_id INTEGER,
    plan TEXT,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    end_date TIMESTAMP WITHOUT TIME ZONE,
    mrr NUMERIC,
    status TEXT,
    cancelled_at TIMESTAMP WITHOUT TIME ZONE,
    cancellation_reason TEXT,
    account_id BIGINT,
    seat_count INTEGER,
    plan_id INTEGER
);

-- saas.subscription_events: 3741 rows.
CREATE TABLE saas.subscription_events (
    event_id INTEGER NOT NULL,
    subscription_id INTEGER,
    user_id INTEGER,
    event_type TEXT,
    event_time TIMESTAMP WITHOUT TIME ZONE,
    from_plan TEXT,
    to_plan TEXT,
    mrr_delta NUMERIC,
    account_id BIGINT,
    actor_user_id INTEGER,
    seats_delta INTEGER
);

-- saas.trials: 250 rows.
CREATE TABLE saas.trials (
    trial_id BIGINT NOT NULL,
    account_id BIGINT,
    started_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    converted_at TIMESTAMP WITH TIME ZONE,
    converted_subscription_id BIGINT
);

-- saas.seats: 1556 rows.
CREATE TABLE saas.seats (
    seat_id BIGINT NOT NULL,
    account_id BIGINT,
    user_id INTEGER,
    activated_at TIMESTAMP WITH TIME ZONE,
    deactivated_at TIMESTAMP WITH TIME ZONE
);

-- saas.events: 53534 rows.
CREATE TABLE saas.events (
    event_id INTEGER NOT NULL,
    user_id INTEGER,
    event_type TEXT,
    occurred_at TIMESTAMP WITHOUT TIME ZONE,
    properties TEXT,
    account_id BIGINT,
    feature_id INTEGER
);

-- saas.support_tickets: 1249 rows.
CREATE TABLE saas.support_tickets (
    ticket_id BIGINT NOT NULL,
    account_id BIGINT,
    opened_by_user_id INTEGER,
    opened_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    priority TEXT,
    category TEXT,
    csat INTEGER
);

-- saas.invoices: 4201 rows.
CREATE TABLE saas.invoices (
    invoice_id INTEGER NOT NULL,
    user_id INTEGER,
    subscription_id INTEGER,
    amount NUMERIC,
    status TEXT,
    issued_date TIMESTAMP WITHOUT TIME ZONE,
    paid_date TIMESTAMP WITHOUT TIME ZONE,
    due_date TIMESTAMP WITHOUT TIME ZONE,
    account_id BIGINT
);

-- saas.payment_attempts: 5690 rows.
CREATE TABLE saas.payment_attempts (
    attempt_id INTEGER NOT NULL,
    invoice_id INTEGER,
    user_id INTEGER,
    subscription_id INTEGER,
    amount NUMERIC,
    status TEXT,
    failure_reason TEXT,
    attempt_number INTEGER,
    attempted_at TIMESTAMP WITHOUT TIME ZONE,
    account_id BIGINT
);
