
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
StoreMetrics AS (
    SELECT
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
),
CustomerActivity AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
    HAVING COUNT(DISTINCT ws.ws_order_number) > 5
)
SELECT
    cm.c_customer_sk,
    cm.total_orders,
    cm.max_order_value,
    sm.s_store_sk,
    sm.total_profit,
    sm.avg_sales_price,
    rs.rank_price
FROM CustomerActivity cm
JOIN StoreMetrics sm ON cm.c_customer_sk = sm.s_store_sk
LEFT JOIN RankedSales rs ON sm.s_store_sk = rs.web_site_sk
WHERE sm.total_profit > 1000
AND (cm.max_order_value IS NOT NULL OR sm.avg_sales_price IS NULL)
ORDER BY cm.total_orders DESC, sm.total_profit DESC;
