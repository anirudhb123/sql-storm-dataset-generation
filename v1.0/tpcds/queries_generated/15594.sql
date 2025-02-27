
SELECT c.customer_id, SUM(ss.ext_sales_price) AS total_sales
FROM customer c
JOIN store_sales ss ON c.customer_sk = ss.customer_sk
GROUP BY c.customer_id
ORDER BY total_sales DESC
LIMIT 10;
