CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    birth_date DATE,
    employer VARCHAR(100)
);

CREATE TABLE cards (
    id SERIAL PRIMARY KEY,
    card_number VARCHAR(20),
    client_id INT REFERENCES clients(id) ON DELETE CASCADE,
    card_type VARCHAR(50),
    issue_date DATE,
    "expiry_date" DATE
);

CREATE TABLE operations (
    id SERIAL PRIMARY KEY,
    operation_name VARCHAR(50)
);

CREATE TABLE transactions (
    id SERIAL,
    card_id INT REFERENCES cards(id) ON DELETE CASCADE,
    transaction_date DATE,
    amount INT,
    operation_id INT REFERENCES operations(id) ON DELETE CASCADE
) PARTITION BY RANGE(transaction_date);

CREATE TABLE insufficient_funds (
    id SERIAL PRIMARY KEY,
    card_id INT REFERENCES cards(id) ON DELETE CASCADE,
    transaction_date DATE,
    amount INTEGER,
    operation_id INT REFERENCES operations(id) ON DELETE CASCADE
);

CREATE TABLE card_is_invalid (
    id SERIAL PRIMARY KEY,
    card_id INT REFERENCES cards(id) ON DELETE CASCADE,
    transaction_date DATE,
    amount INTEGER,
    operation_id INT REFERENCES operations(id) ON DELETE CASCADE,
    "expiry_date" DATE
);