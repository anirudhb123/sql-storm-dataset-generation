
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level,
        CAST(c.c_first_name AS varchar(50)) AS path
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        CAST(sh.path || ' -> ' || c.c_first_name AS varchar(50))
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN SalesHierarchy sh ON sr.sr_customer_sk = sh.c_customer_sk
),
DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY dd.d_date
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.level,
    display.path,
    ds.total_profit,
    ds.total_orders
FROM SalesHierarchy sh
LEFT JOIN (
    SELECT 
        d.d_date,
        ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS rn,
        d.total_profit,
        d.total_orders
    FROM DailySales d
) AS ds ON sh.level = ds.rn
WHERE (sh.level % 2 = 0 OR ds.total_profit IS NOT NULL)
ORDER BY sh.c_customer_sk, sh.level;
