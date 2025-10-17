CREATE OR REPLACE PROCEDURE generate_test_data(

)
LANGUAGE plpgsql
AS $$
DECLARE
    max_client_id INT;
    max_card_id INT;
    max_operation_id INT;
    max_transaction_id INT;
BEGIN
    RAISE NOTICE 'Начата генерация данных!';

    -- Получаем текущие максимальные ID (или 0 если таблицы пустые)
    -- Будет использоваться, если захотим заново генерировать данные, сохраняя их
    SELECT COALESCE(MAX(id), 0) INTO max_client_id FROM clients;
    SELECT COALESCE(MAX(id), 0) INTO max_card_id FROM cards;
    SELECT COALESCE(MAX(id), 0) INTO max_operation_id FROM operations;
    SELECT COALESCE(MAX(id), 0) INTO max_transaction_id FROM transactions;

    -- Вставка данных в таблицу clients
    INSERT INTO clients(id, full_name, email, phone, birth_date, employer)
    WITH clients_data AS (
    SELECT
        max_client_id + i AS id,
        'Fullname' || (max_client_id + i) AS full_name,
        'email' || (max_client_id + i) || '@company.com' AS email,
        '+79' || (max_client_id + i + 100000000) AS phone,
        '1970-01-01'::DATE + (random() * ('2010-01-01'::DATE - '1970-01-01'::DATE))::INT AS birth_date,
        'Employer' || (max_client_id + i) AS employer
    FROM generate_series(1, 300000) i)

    SELECT *
    FROM clients_data;

    RAISE NOTICE 'Данные для таблицы clients добавлены';

    -- Вставка данных в таблицу cards
    INSERT INTO cards(id, card_number, client_id, card_type, issue_date, expiry_date)
    WITH cards_data AS (
    SELECT
        max_card_id + i AS id,
        '4276' || (max_card_id + i + 100000000000) AS card_number,
        FLOOR(RANDOM() * 299999) + 1 + max_client_id AS client_id,
        CASE(FLOOR(RANDOM()*3))
            WHEN 0 THEN 'Visa'
            WHEN 1 THEN 'Mastercard'
            ELSE 'МИР'
        END AS card_type,
        '2020-07-07'::DATE + (i % 1900) AS issue_date,
        '2021-09-09'::DATE + (i % 1900) + INTERVAL '3 YEARS' AS expiry_date
    FROM generate_series(1, 500000) i)

    SELECT *
    FROM cards_data;

    RAISE NOTICE 'Данные для таблицы cards добавлены';

    -- Вставка данных в таблицу operations
    INSERT INTO operations(id, operation_name)
    WITH operations_data AS (
    SELECT
        max_operation_id + i AS id,
        CASE (floor(random()*4))
            WHEN 0 THEN 'Покупка'
            ELSE 'Пополнение'
        END AS operation_name
    FROM generate_series(1, 1500000) i)

    SELECT *
    FROM operations_data;

    RAISE NOTICE 'Данные для таблицы operations добавлены';

    -- Вставка данных с проверкой баланса и срока действия карты
    INSERT INTO transactions (id, card_id, transaction_date, amount, operation_id)
    WITH transactions_data AS (
        SELECT
            max_transaction_id + i as id,
            FLOOR(random() * 499999) + 1 + max_card_id as card_id,
            '2020-01-01'::DATE + (random() * (current_date - '2020-01-01'::DATE))::INT as transaction_date,
            100 + (random() * 400000)::INT as amount,
            max_operation_id + i AS operation_id
        FROM generate_series(1, 1500000) i
    ),
    transactions_with_cards AS (
        SELECT
            td.*,
            c.expiry_date,
            o.operation_name,
            CASE
                WHEN o.operation_name = 'Пополнение' THEN td.amount
                ELSE -td.amount
            END AS balance_change
        FROM transactions_data td
        JOIN cards c ON c.id = td.card_id
        JOIN operations o ON o.id = td.operation_id
        WHERE td.transaction_date <= c.expiry_date
    ),
    calculated_balances AS (
        SELECT
            *,
            SUM(balance_change) OVER (
                PARTITION BY card_id
                ORDER BY transaction_date, id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS current_balance
        FROM transactions_with_cards
    ),
    valid_transactions AS (
        SELECT
            id, card_id, transaction_date, amount, operation_id,
            current_balance,
            'valid' as status
        FROM calculated_balances
        WHERE current_balance >= 0
    )
    SELECT id, card_id, transaction_date, amount, operation_id
    FROM valid_transactions;

    RAISE NOTICE 'Данные для таблицы transactions добавлены';

    -- Запись отклоненных транзакций (недостаточно средств)
    INSERT INTO insufficient_funds (card_id, transaction_date, amount, operation_id)
    WITH transactions_data AS (
        SELECT
            max_transaction_id + i as id,
            FLOOR(random() * 499999) + 1 + max_card_id as card_id,
            '2020-01-01'::DATE + (random() * (current_date - '2020-01-01'::DATE))::INT as transaction_date,
            100 + (random() * 400000)::INT as amount,
            max_operation_id + i AS operation_id
        FROM generate_series(1, 1500000) i
    ),
    transactions_with_cards AS (
        SELECT
            td.*,
            c.expiry_date,
            o.operation_name,
            CASE
                WHEN o.operation_name = 'Пополнение' THEN td.amount
                ELSE -td.amount
            END AS balance_change
        FROM transactions_data td
        JOIN cards c ON c.id = td.card_id
        JOIN operations o ON o.id = td.operation_id
        WHERE td.transaction_date <= c.expiry_date
    ),
    calculated_balances AS (
        SELECT
            *,
            SUM(balance_change) OVER (
                PARTITION BY card_id
                ORDER BY transaction_date, id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS current_balance
        FROM transactions_with_cards
    )
    SELECT card_id, transaction_date, amount, operation_id
    FROM calculated_balances
    WHERE current_balance < 0;

    RAISE NOTICE 'Данные для таблицы insufficient_funds добавлены';

    -- Запись отклоненных транзакций (истёк срок действия карты)
    INSERT INTO card_is_invalid(card_id, transaction_date, amount, operation_id, expiry_date)
    WITH transactions_data AS (
        SELECT
            max_transaction_id + i as id,
            FLOOR(random() * 499999) + 1 + max_card_id as card_id,
            '2020-01-01'::DATE + (random() * (current_date - '2020-01-01'::DATE))::INT as transaction_date,
            100 + (random() * 400000)::INT as amount,
            max_operation_id + i AS operation_id
        FROM generate_series(1, 1500000) i
    ),
    expired_transactions AS (
        SELECT
            td.*,
            c.expiry_date,
            o.operation_name
        FROM transactions_data td
        JOIN cards c ON c.id = td.card_id
        JOIN operations o ON o.id = td.operation_id
        WHERE td.transaction_date > c.expiry_date
    )
    SELECT card_id, transaction_date, amount, operation_id, expiry_date
    FROM expired_transactions;

    RAISE NOTICE 'Данные для таблицы card_is_invalid добавлены';

    RAISE NOTICE 'Генерация данных завершена успешно!';
END;
$$;

-- Процедура по очистке данных
CREATE OR REPLACE PROCEDURE truncate_test_data()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Очистка тестовых данных...';

    TRUNCATE TABLE
        card_is_invalid,
        insufficient_funds,
        transactions,
        operations,
        cards,
        clients
    RESTART IDENTITY CASCADE;

    RAISE NOTICE 'Все таблицы очищены!';
END;
$$;

