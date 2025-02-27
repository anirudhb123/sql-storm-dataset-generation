
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        ir.ws_item_sk,
        ir.ws_net_profit,
        COALESCE(ar.total_returned, 0) AS total_returned,
        CAST(ws_net_profit AS DECIMAL(10, 2)) - COALESCE(ar.total_returned, 0) * 10 AS adjusted_net_profit
    FROM 
        RankedSales ir
    LEFT JOIN 
        AggregateReturns ar ON ir.ws_item_sk = ar.cr_item_sk
    WHERE 
        ir.profit_rank = 1
)
SELECT 
    s.ws_item_sk,
    s.ws_net_profit,
    s.adjusted_net_profit,
    CASE 
        WHEN s.adjusted_net_profit > 1000 THEN 'High Profit'
        WHEN s.adjusted_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    DATE(d.d_date) AS sales_date
FROM 
    SalesWithReturns s
JOIN 
    date_dim d ON d.d_date_sk = s.ws_sold_date_sk
WHERE 
    s.adjusted_net_profit IS NOT NULL
    AND (s.total_returned != 0 OR s.ws_net_profit > 500)
ORDER BY 
    s.adjusted_net_profit DESC
LIMIT 100
UNION ALL
SELECT 
    '0' AS ws_item_sk,
    0 AS ws_net_profit,
    NULL AS adjusted_net_profit,
    'Total Loss' AS profit_category,
    NULL AS sales_date
FROM 
    dual
WHERE NOT EXISTS (
    SELECT 1 
    FROM SalesWithReturns
);
