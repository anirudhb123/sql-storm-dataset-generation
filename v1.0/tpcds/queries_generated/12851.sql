
SELECT ca.city, COUNT(DISTINCT c.c_customer_sk) AS customer_count, SUM(ss.ss_net_paid) AS total_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.city
ORDER BY total_sales DESC
LIMIT 10;
