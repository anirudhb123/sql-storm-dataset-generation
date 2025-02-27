
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_qty_trans AS sales_qty,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM web_sales
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_qty,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        ss_item_sk,
        total_sales_qty,
        avg_profit,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales_qty DESC) AS rn
    FROM SalesSummary
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    ci.i_current_price,
    COALESCE(ts.total_sales_qty, 0) AS total_sales_qty,
    COALESCE(ts.avg_profit, 0) AS avg_profit,
    COALESCE(ts.order_count, 0) AS order_count,
    CAST(DATEADD(DAY, 7, d.d_date) AS VARCHAR) AS next_week_date,
    FULL OUTER JOIN (
        SELECT 
            DISTINCT c.c_current_addr_sk
        FROM customer c
        WHERE c.c_birth_year >= 1980
    ) AS customer_info ON cei.c_customer_sk = ws_ship_customer_sk
FROM item ci
LEFT JOIN TopItems ts ON ci.i_item_sk = ts.ss_item_sk
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(d_date_sk)
    FROM date_dim
    WHERE d_year = 2023
)
WHERE ts.rn <= 10
AND ci.i_current_price IS NOT NULL
ORDER BY total_sales_qty DESC;
