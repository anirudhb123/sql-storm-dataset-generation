
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales
), 
FilteredSales AS (
    SELECT 
        r.ws_sold_date_sk,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.ProfitRank = 1
        AND (r.ws_net_profit IS NOT NULL OR r.ws_quantity > 0)
), 
TotalReturns AS (
    SELECT 
        SUM(sr_return_quantity) AS total_store_returns,
        SUM(cr_return_quantity) AS total_catalog_returns,
        SUM(wr_return_quantity) AS total_web_returns
    FROM 
        store_returns sr
    FULL OUTER JOIN catalog_returns cr ON sr_item_sk = cr_item_sk
    FULL OUTER JOIN web_returns wr ON sr_item_sk = wr_item_sk
), 
SalesWithReturns AS (
    SELECT 
        fs.ws_item_sk,
        fs.ws_quantity,
        COALESCE(tr.total_store_returns, 0) AS total_store_returns,
        COALESCE(tr.total_catalog_returns, 0) AS total_catalog_returns,
        COALESCE(tr.total_web_returns, 0) AS total_web_returns,
        fs.ws_net_profit
    FROM 
        FilteredSales fs
    LEFT JOIN TotalReturns tr ON fs.ws_item_sk = tr.ws_item_sk
    ORDER BY fs.ws_net_profit DESC
)
SELECT 
    f.ws_item_sk,
    f.ws_quantity,
    f.ws_net_profit,
    f.total_store_returns + f.total_catalog_returns + f.total_web_returns AS total_returns,
    CASE 
        WHEN f.ws_net_profit IS NULL THEN 'Profit Data Missing'
        WHEN f.ws_quantity IS NULL THEN 'Quantity Data Missing'
        WHEN f.ws_net_profit > 500 THEN 'High Profit Item'
        ELSE 'Standard Item'
    END AS item_classification
FROM 
    SalesWithReturns f
WHERE 
    (f.total_returns IS NOT NULL AND f.total_returns BETWEEN 1 AND 100) 
    OR (f.total_store_returns > 20 AND f.ws_net_profit IS NOT NULL)
    OR f.ws_quantity IS NULL
UNION ALL
SELECT 
    99999999 AS ws_item_sk,
    NULL AS ws_quantity,
    NULL AS ws_net_profit,
    NULL AS total_returns,
    'Aggregate Row' AS item_classification
FROM 
    DUAL
ORDER BY 
    item_classification, 
    ws_net_profit DESC NULLS LAST;
