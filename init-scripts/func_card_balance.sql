-- Суммарный остаток по всем картам клиента на определенный момент времени.
-- Входные параметры функции: ИД клиента и Дата/время


CREATE OR REPLACE FUNCTION get_client_balance(
    input_client_id INTEGER,
    input_timestamp TIMESTAMP
) 
RETURNS INTEGER AS $$
DECLARE
    total_balance INTEGER;
BEGIN
    SELECT COALESCE(SUM(
        CASE 
            WHEN o.operation_name = 'Пополнение' THEN t.amount 
            WHEN o.operation_name = 'Покупка' THEN -t.amount 
        END
    ), 0) INTO total_balance
    FROM clients cl
    JOIN cards c ON cl.id = c.client_id
    JOIN transactions t ON c.id = t.card_id
    JOIN operations o ON t.operation_id = o.id
    WHERE cl.id = input_client_id
      AND t.transaction_date <= input_timestamp;
    
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql;
