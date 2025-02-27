
WITH RecursiveSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws.web_site_sk, ws.web_name
),
TopSales AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM RecursiveSales
),
CustomerCounts AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ts.web_name,
    ts.total_net_profit,
    cc.order_count,
    COALESCE(cc.order_count, 0) AS total_orders,
    CASE
        WHEN cc.order_count IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM TopSales ts
LEFT JOIN CustomerCounts cc ON ts.web_site_sk = cc.c_customer_sk
WHERE ts.rank <= 10
UNION ALL
SELECT 
    'Total' AS web_name,
    SUM(ts.total_net_profit) AS total_net_profit,
    NULL AS order_count,
    NULL AS total_orders,
    'Aggregate' AS order_status
FROM TopSales ts
WHERE ts.rank <= 10
ORDER BY total_net_profit DESC;
