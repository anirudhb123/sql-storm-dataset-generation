
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        ws_net_profit,
        ws_quantity,
        ws_sales_price,
        (CASE 
            WHEN ws_quantity > 100 THEN 'High Volume'
            WHEN ws_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
         END) AS volume_category
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    WHERE sr_return_amt_inc_tax IS NOT NULL
    GROUP BY sr_item_sk
),
SalesReturnsSummary AS (
    SELECT 
        r.ws_item_sk,
        r.profit_rank,
        r.ws_net_profit,
        r.volume_category,
        COALESCE(a.total_returns, 0) AS total_returns,
        COALESCE(a.total_return_amt, 0) AS total_return_amt
    FROM RankedSales r
    LEFT JOIN AggregateReturns a ON r.ws_item_sk = a.sr_item_sk
)
SELECT 
    s.ws_item_sk,
    MAX(s.ws_net_profit) AS max_profit,
    SUM(CASE 
        WHEN s.total_returns > 0 THEN s.ws_net_profit * 0.9 
        ELSE s.ws_net_profit 
    END) AS adjusted_profit,
    LISTAGG(DISTINCT s.volume_category || ': ' || s.total_returns || ' returns', ', ') AS volume_summary
FROM SalesReturnsSummary s
WHERE s.profit_rank <= 10
GROUP BY s.ws_item_sk, s.profit_rank, s.ws_net_profit, s.volume_category
ORDER BY adjusted_profit DESC
LIMIT 5;
