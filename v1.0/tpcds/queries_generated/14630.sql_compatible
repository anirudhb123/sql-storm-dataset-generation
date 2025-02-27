
SELECT ca.city, COUNT(DISTINCT c.customer_id) AS customer_count, SUM(ss.ext_sales_price) AS total_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ca.ca_state = 'CA' AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
GROUP BY ca.city
ORDER BY total_sales DESC
LIMIT 10;
