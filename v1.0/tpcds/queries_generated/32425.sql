
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        0 AS purchase_depth,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.purchase_depth + 1,
        SUM(ws.ws_net_profit) AS total_profit
    FROM  SalesHierarchy sh
    JOIN customer c ON c.c_customer_sk = (SELECT s.c_customer_sk FROM customer s WHERE s.c_customer_id = (SELECT c2.c_customer_id FROM customer c2 WHERE c2.c_customer_sk = sh.c_customer_sk))
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.purchase_depth
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.purchase_depth,
    ROUND(SUM(CASE WHEN sh.total_profit IS NOT NULL THEN sh.total_profit ELSE 0 END), 2) AS cumulative_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY sh.purchase_depth DESC) AS order_rank
FROM SalesHierarchy sh
LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
WHERE sh.purchase_depth <= 10
GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.purchase_depth
HAVING COUNT(ws.ws_order_number) > 0
ORDER BY cumulative_profit DESC, total_orders DESC
LIMIT 100
OFFSET 0;
