
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_profit,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS total_sales_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),

AggregatedReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        MAX(cr_return_tax) AS max_return_tax
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_item_sk
),

SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_profit,
        ar.total_returns,
        ar.total_return_amount,
        ar.max_return_tax,
        CASE 
            WHEN ar.total_returns IS NULL THEN 'No Returns'
            ELSE 'Returns Exist'
        END AS return_status
    FROM 
        RankedSales rs
    LEFT JOIN 
        AggregatedReturns ar ON rs.ws_item_sk = ar.cr_item_sk
)

SELECT 
    swr.ws_item_sk,
    swr.ws_order_number,
    swr.ws_net_profit,
    swr.total_returns,
    swr.total_return_amount,
    swr.max_return_tax,
    CASE 
        WHEN swr.return_status = 'No Returns' THEN 'Profitable'
        WHEN swr.return_status = 'Returns Exist' AND swr.ws_net_profit - COALESCE(swr.total_return_amount, 0) > 0 THEN 'Returns Adjusted Profit'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    SalesWithReturns swr
WHERE 
    swr.profit_rank <= 5
ORDER BY 
    swr.ws_item_sk, swr.ws_order_number DESC
LIMIT 100
UNION ALL
SELECT 
    i.i_item_sk,
    NULL AS ws_order_number,
    AVG(i.i_current_price) AS avg_price,
    NULL AS total_returns, 
    NULL AS total_return_amount,
    NULL AS max_return_tax,
    'Item Only' AS return_status
FROM 
    item i
WHERE 
    NOT EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk) 
GROUP BY 
    i.i_item_sk
HAVING 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
ORDER BY 
    NULL;
