
SELECT c.c_customer_id, 
       ca.ca_city, 
       SUM(cs.cs_quantity) AS total_quantity_sold
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
GROUP BY c.c_customer_id, ca.ca_city
ORDER BY total_quantity_sold DESC
LIMIT 10;
