
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_month = 12
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    INNER JOIN sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    WHERE ws.ws_sales_price > 50
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT c.c_first_name, c.c_last_name, 
       ca.ca_city,
       RANK() OVER (PARTITION BY ca.ca_city ORDER BY sh.total_sales DESC) AS sales_rank,
       sh.total_sales,
       (SELECT COUNT(DISTINCT ws.ws_order_number) 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
       ) AS order_count
FROM sales_hierarchy sh
JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
ORDER BY sales_rank, sh.total_sales DESC
LIMIT 100;
