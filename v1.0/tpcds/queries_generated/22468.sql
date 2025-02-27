
WITH RankedOrders AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS order_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sale_price > 0
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2458000
),

FilteredReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(fo.total_return_amount, 0) AS total_returned,
    ROUND((ro.cumulative_profit - COALESCE(fo.total_return_amount, 0)) / NULLIF(ro.order_rank, 0), 2) AS avg_profit_per_order
FROM 
    RankedOrders ro
JOIN 
    item i ON ro.ws_item_sk = i.i_item_sk
LEFT JOIN 
    FilteredReturns fo ON ro.ws_item_sk = fo.sr_item_sk
WHERE 
    ro.order_rank = 1
ORDER BY 
    avg_profit_per_order DESC
FETCH FIRST 10 ROWS ONLY;

-- This query identifies the top 10 products by average profit per order, incorporating cumulative sales 
-- and filtering based on returns while managing NULL values seamlessly.
