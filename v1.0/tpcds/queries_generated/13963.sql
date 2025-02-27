
SELECT ca.city, COUNT(DISTINCT c.customer_id) AS customer_count
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store s ON s.s_closed_date_sk IS NULL
WHERE ca.ca_state = 'CA'
GROUP BY ca.city
ORDER BY customer_count DESC
LIMIT 10;
