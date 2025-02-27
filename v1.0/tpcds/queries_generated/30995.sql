
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS returns_count,
        SUM(sr_return_amt) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesVsReturns AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_sales,
        sd.order_count,
        rs.returns_count,
        rs.total_returned_amount
    FROM SalesData sd
    LEFT JOIN ReturnStats rs ON sd.ws_ship_mode_sk = rs.sr_item_sk
)
SELECT 
    dh.d_date AS sale_date,
    COALESCE(sv.total_sales, 0) AS total_sales,
    COALESCE(sv.order_count, 0) AS order_count,
    COALESCE(sv.returns_count, 0) AS returns_count,
    COALESCE(sv.total_returned_amount, 0) AS total_returned_amount,
    CAST(100.0 * COALESCE(sv.returns_count, 0) / NULLIF(sv.order_count, 0) AS DECIMAL(5,2)) AS return_rate
FROM date_dim dh
LEFT JOIN SalesVsReturns sv ON dh.d_date_sk = sv.ws_sold_date_sk
WHERE dh.d_year = 2023
ORDER BY sale_date;
