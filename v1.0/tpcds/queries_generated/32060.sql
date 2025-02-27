
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, 1 AS level
    FROM customer
    WHERE c_birth_year IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, sh.level + 1
    FROM customer c
    INNER JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
),
filtered_customers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date, 
           SUM(ws_ext_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM d.d_date) ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
),
top_sales AS (
    SELECT f.c_customer_id, f.c_first_name, f.c_last_name, f.total_sales
    FROM filtered_customers f
    WHERE f.sales_rank <= 5
)
SELECT a.ca_city, COUNT(DISTINCT f.c_customer_id) AS num_customers,
       AVG(f.total_sales) AS avg_sales
FROM customer_address a
LEFT JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN top_sales f ON c.c_customer_id = f.c_customer_id
GROUP BY a.ca_city
HAVING COUNT(DISTINCT f.c_customer_id) > 0
ORDER BY avg_sales DESC;
