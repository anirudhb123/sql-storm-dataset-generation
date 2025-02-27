
SELECT ca.city, COUNT(DISTINCT c.customer_id) AS total_customers
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY ca.city
ORDER BY total_customers DESC
LIMIT 10;
