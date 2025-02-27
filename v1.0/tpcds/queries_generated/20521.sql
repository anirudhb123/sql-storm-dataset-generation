
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS OverallProfitRank
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
),
ItemReturns AS (
    SELECT 
        cr_item_sk AS item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_value
    FROM catalog_returns
    WHERE cr_return_quantity IS NOT NULL
    GROUP BY cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        s.item_sk,
        COALESCE(r.total_returns, 0) AS total_returns,
        SUM(s.ws_quantity) AS total_sold,
        SUM(s.ws_net_profit) AS total_net_profit
    FROM RankedSales s
    LEFT JOIN ItemReturns r ON s.ws_item_sk = r.item_sk
    GROUP BY s.item_sk, r.total_returns
)
SELECT 
    s.item_sk,
    s.total_sold,
    s.total_returns,
    s.total_net_profit,
    CASE 
        WHEN s.total_net_profit >= 1000 THEN 'High Profit'
        WHEN s.total_net_profit BETWEEN 500 AND 999 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CASE 
        WHEN s.total_returns > 0 AND s.total_sold > 0 THEN 
            ROUND((s.total_returns::decimal / s.total_sold) * 100, 2)
        ELSE 
            NULL
    END AS return_rate_percentage
FROM SalesWithReturns s
JOIN item i ON s.item_sk = i.i_item_sk
WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item)
AND (s.total_returns IS NULL OR s.total_returns > 5)
ORDER BY s.total_net_profit DESC, profit_category
LIMIT 10;
