
WITH RECURSIVE SalesHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_birth_year, e.employee_id AS manager_id, 
           0 AS level
    FROM customer c
    LEFT JOIN employee e ON c.employee_id = e.employee_id
    WHERE e.manager_id IS NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_birth_year, e.employee_id AS manager_id, 
           level + 1
    FROM customer c
    JOIN employee e ON c.employee_id = e.employee_id
    JOIN SalesHierarchy sh ON sh.manager_id = e.employee_id
),
SalesDetails AS (
    SELECT ws.ws_item_sk, ws.ws_sales_price, ws.ws_quantity, 
           d.d_date, d.d_week_seq, 
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY d.d_date DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
),
TopSales AS (
    SELECT item_id, SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM SalesDetails
    WHERE sales_rank <= 10
    GROUP BY ws_item_sk
)
SELECT ch.c_first_name, ch.c_last_name, 
       MAX(ash.total_sales) AS top_sales, 
       COUNT(DISTINCT ch.manager_id) AS direct_reports
FROM SalesHierarchy ch
LEFT JOIN TopSales ash ON ch.c_customer_sk = ash.item_id
WHERE (ch.c_birth_year IS NOT NULL OR ch.c_birth_year < 1990)
GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
HAVING COUNT(DISTINCT ch.c_customer_sk) > 2
ORDER BY top_sales DESC
FETCH FIRST 5 ROWS ONLY;
