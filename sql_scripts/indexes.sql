
-- Создание индексов для различных запросов
CREATE INDEX idx_clients ON clients(full_name, email, birth_date, employer);
CREATE INDEX idx_cards ON cards(card_number, card_type, issue_date, expiry_date)
CREATE INDEX idx_operations ON operations(operation_name);
CREATE INDEX idx_transactions ON transactions(transaction_date, amount);
CREATE INDEX idx_insufficient_funds ON insufficient_funds(transaction_date, amount);
CREATE INDEX idx_card_is_invalid ON card_is_invalid(transaction_date, amount, expiry_date);


DROP INDEX IF EXISTS idx_clients, idx_cards, idx_operations, 
idx_transactions, idx_insufficient_funds, idx_cars_is_invalid;


-- Создание индекса для моих sql скриптов (5_queries.sql)
CREATE INDEX idx_transactions_operation_id ON transactions (operation_id);
CREATE INDEX idx_transactions_card_id ON transactions (card_id);
CREATE INDEX idx_cards_client_id ON cards (client_id);
CREATE INDEX idx_operations_name_id ON operations (operation_name, id);
CREATE INDEX idx_transactions_card_id_date ON transactions (card_id, transaction_date);
CREATE INDEX idx_transactions_card_id_count ON transactions (card_id);

DROP INDEX IF EXISTS idx_transactions_operation_id, idx_transactions_card_id, 
idx_cards_client_id, idx_operations_name_id, idx_transactions_card_id_date, idx_transactions_card_id_count;