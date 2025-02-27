
WITH CustomerReturns AS (
    SELECT 
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_store_sk,
        COUNT(*) OVER (PARTITION BY sr_store_sk) AS total_returns,
        SUM(sr_return_amt) OVER (PARTITION BY sr_store_sk) AS total_return_amt
    FROM store_returns 
    WHERE sr_return_quantity > 0
),
AvgReturnStats AS (
    SELECT 
        sr_store_sk,
        AVG(sr_return_amt) AS avg_return_amt_per_item,
        SUM(sr_return_quantity) AS total_return_quantity_per_store
    FROM CustomerReturns
    GROUP BY sr_store_sk
),
StoreSalesStats AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_store_sk
),
CombinedStats AS (
    SELECT 
        s.s_store_sk,
        COALESCE(a.avg_return_amt_per_item, 0) AS avg_return_amt_per_item,
        COALESCE(a.total_return_quantity_per_store, 0) AS total_return_quantity_per_store,
        COALESCE(b.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(b.total_net_profit, 0) AS total_net_profit,
        (COALESCE(a.total_return_quantity_per_store, 0) / NULLIF(COALESCE(b.total_sales_quantity, 0), 0)) * 100 AS return_rate_percentage,
        ROW_NUMBER() OVER (ORDER BY COALESCE(a.total_return_quantity_per_store, 0) DESC) AS store_rank
    FROM store s
    LEFT JOIN AvgReturnStats a ON s.s_store_sk = a.sr_store_sk
    LEFT JOIN StoreSalesStats b ON s.s_store_sk = b.ss_store_sk
)
SELECT 
    s_store_sk,
    avg_return_amt_per_item,
    total_return_quantity_per_store,
    total_sales_quantity,
    total_net_profit,
    return_rate_percentage,
    store_rank
FROM CombinedStats
WHERE return_rate_percentage IS NOT NULL
AND total_sales_quantity > 0
ORDER BY return_rate_percentage DESC, total_net_profit ASC;

SELECT 
    sm.sm_type,
    COUNT(DISTINCT wr_returning_cdemo_sk) AS unique_customers_returned,
    SUM(wr_return_amt_inc_tax) AS total_return_value,
    s.s_store_id
FROM web_returns wr
JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON ws.ws_warehouse_sk = s.s_store_sk
WHERE wr_returned_date_sk > ws.ws_sold_date_sk
GROUP BY sm.sm_type, s.s_store_id
ORDER BY total_return_value DESC
FETCH FIRST 10 ROWS ONLY;
