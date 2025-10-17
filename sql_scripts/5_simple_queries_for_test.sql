"""
ЗАДАЧА 1
RANK() - Ранжирование клиентов по сумме покупки
"""

WITH top_clients AS (
	SELECT full_name, sum(amount) AS sum,
	RANK() OVER(ORDER BY sum(amount) DESC) AS rnk
	FROM transactions t
	JOIN operations o ON o.id = t.operation_id
	JOIN cards c ON c.id = t.card_id 
	JOIN clients cl ON cl.id = c.client_id 
	WHERE o.operation_name = 'Покупка'
	GROUP BY full_name
	ORDER BY sum DESC
)

SELECT full_name, sum, rnk
FROM top_clients

"""
ЗАДАЧА 2
LAG() - Сравнение текущей транзакции с предыдущей
"""
WITH amount_different AS (
	SELECT card_number, amount,
	LAG(amount) OVER(PARTITION BY card_id ORDER BY transaction_date) AS lg,
	amount - LAG(amount) OVER(PARTITION BY card_id ORDER BY transaction_date) AS amount_diff
	FROM transactions t
	JOIN cards c ON c.id = t.card_id 
)

SELECT card_number, amount, COALESCE(lg, 0) AS previous_amount, 
COALESCE(amount_diff, 0) AS amount_diff
FROM amount_different


"""
ЗАДАЧА 3
SUM() с нарастающим итогом
"""
WITH total AS (
	SELECT card_number, amount,
	SUM(amount) OVER(PARTITION BY card_id ORDER BY transaction_date) AS running_total
	FROM transactions t
	JOIN cards c ON c.id = t.card_id 
)

SELECT card_number, amount, running_total
FROM total


"""
ЗАДАЧА 4
NTILE() - Разделение карт на группы по активности (кол-во транзакций)
"""
WITH group_active AS(
	SELECT card_number,
	count(t.id) AS transaction_count,
	NTILE(4) OVER(ORDER BY COUNT(t.id)) AS gr_active
	FROM transactions t
	JOIN cards c ON c.id = t.card_id
	GROUP BY card_number
)

SELECT card_number, transaction_count, gr_active
FROM group_active
ORDER BY gr_active DESC

"""
ЗАДАЧА 5
FIRST_VALUE() - Первая транзакция для каждой карты
"""
WITH first_transaction AS(
	SELECT card_number, transaction_date, amount,
	first_value(amount) over(PARTITION BY card_id ORDER BY transaction_date) AS first_trans
	FROM transactions t
	JOIN cards c ON t.card_id = c.id
)

SELECT card_number, transaction_date, amount, first_trans
FROM first_transaction
