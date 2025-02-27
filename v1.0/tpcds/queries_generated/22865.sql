
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) as price_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month > 0
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        SUM(sr_return_tax) AS total_tax
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 10
),
SalesVsReturns AS (
    SELECT 
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        ws.ws_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(rv.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(rv.total_returns, 0) > 0 THEN 
                SUM(ws.ws_ext_sales_price) / NULLIF(rv.total_returns, 0)
            ELSE 
                NULL
        END AS avg_price_per_return
    FROM web_sales ws
    LEFT JOIN HighValueReturns rv ON ws.ws_item_sk = rv.sr_item_sk
    GROUP BY ws.ws_item_sk, rv.total_returns
)
SELECT 
    dw.d_date as sale_date,
    sa.sales_rank,
    sa.total_sold,
    sa.total_returns,
    sa.avg_price_per_return,
    CASE 
        WHEN sa.avg_price_per_return IS NULL THEN 'No Returns'
        WHEN sa.total_sold - sa.total_returns < 0 THEN 'Negative Inventory'
        ELSE 'Normal'
    END AS inventory_status
FROM (
    SELECT 
        DISTINCT d.d_date,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date DESC) as year_position
    FROM date_dim d
    WHERE d.d_date < CURRENT_DATE
) dw
JOIN SalesVsReturns sa ON dw.year_position <= 30
WHERE 
    (sa.total_sold > 100 AND sa.total_returns = 0) 
    OR (sa.avg_price_per_return IS NOT NULL AND sa.avg_price_per_return > 50.00)
ORDER BY dw.d_date DESC, sa.sales_rank
_OPTIONAL; -- Unusual usage of _OPTIONAL to demonstrate semantic peculiarities
