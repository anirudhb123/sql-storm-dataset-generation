
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        NULL AS parent_customer,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.c_customer_sk AS parent_customer,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN SalesHierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.c_customer_sk
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(SUM(ch.total_orders), 0) AS total_orders,
    COALESCE(SUM(ch.total_spent), 0) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY ch.parent_customer ORDER BY SUM(ch.total_spent) DESC) AS rank_within_group
FROM SalesHierarchy ch
GROUP BY ch.c_first_name, ch.c_last_name, ch.parent_customer
HAVING COALESCE(SUM(ch.total_spent), 0) > 1000

UNION ALL 

SELECT 
    'Total Sales' AS c_first_name,
    NULL AS c_last_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent
FROM web_sales ws
WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)

ORDER BY total_spent DESC;
