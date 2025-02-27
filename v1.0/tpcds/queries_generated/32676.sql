
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN Customer_Hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
Total_Sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Sales_Analysis AS (
    SELECT ch.c_customer_id, ch.c_first_name, ch.c_last_name, 
           COALESCE(ts.total_net_paid, 0) AS total_net_paid,
           ROW_NUMBER() OVER (PARTITION BY ch.c_current_cdemo_sk ORDER BY COALESCE(ts.total_net_paid, 0) DESC) AS rank
    FROM Customer_Hierarchy ch
    LEFT JOIN Total_Sales ts ON ch.c_customer_sk = ts.ws_bill_customer_sk
)
SELECT sa.c_customer_id, sa.c_first_name, sa.c_last_name, sa.total_net_paid
FROM Sales_Analysis sa
WHERE sa.rank <= 5
AND sa.total_net_paid > (
    SELECT AVG(total_net_paid) 
    FROM Sales_Analysis 
    WHERE total_net_paid IS NOT NULL
)
ORDER BY sa.total_net_paid DESC
LIMIT 10;

-- Performance benchmarking involving outer joins, correlated subquery, window functions, recursive CTE.
