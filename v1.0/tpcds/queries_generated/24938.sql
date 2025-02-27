
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales) 
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number DESC) AS rn
    FROM catalog_sales
    WHERE cs_net_paid > (SELECT AVG(cs_net_paid) FROM catalog_sales)
),
RankedReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY COUNT(cr_return_quantity) DESC) AS rn
    FROM catalog_returns
    GROUP BY cr_item_sk
),
MaxReturns AS (
    SELECT 
        r.cr_item_sk,
        r.total_returns,
        r.total_return_amount,
        CASE 
            WHEN r.total_returns IS NULL THEN 'No Returns'
            ELSE 'Returns'
        END AS return_status
    FROM RankedReturns r
    WHERE r.total_returns > 0 OR r.total_returns IS NULL
),
AggregatedSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    WHERE ss_net_paid > 0
    GROUP BY ss_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(a.total_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(m.return_status, 'No Returns') AS return_status
FROM item i
LEFT JOIN AggregatedSales a ON i.i_item_sk = a.ss_item_sk
LEFT JOIN MaxReturns r ON i.i_item_sk = r.cr_item_sk
ORDER BY total_profit DESC, total_returns DESC
FETCH FIRST 100 ROWS ONLY;
