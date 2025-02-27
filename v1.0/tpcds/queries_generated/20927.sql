
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS TotalSales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS SalesRank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price > 0
)

SELECT 
    cr.cr_item_sk,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    MAX(cr.cr_returned_date_sk) AS last_returned_date,
    CASE 
        WHEN COUNT(cr.cr_order_number) > 0 THEN 'Returns Exist'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN SUM(cr.cr_return_amount) IS NULL THEN 'No Amount'
        ELSE
            CASE 
                WHEN SUM(cr.cr_return_amount) > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = cr.cr_item_sk) 
                THEN 'Above Average Returns'
                ELSE 'Below Average Returns'
            END
    END AS return_evaluation
FROM catalog_returns cr
LEFT JOIN RankedSales rs ON cr.cr_item_sk = rs.ws_item_sk
WHERE rs.ProfitRank = 1
GROUP BY cr.cr_item_sk
HAVING COUNT(cr.cr_order_number) > 0 AND MAX(cr.cr_returned_date_sk) >= 20230101
ORDER BY num_returns DESC, total_return_amount ASC
LIMIT 10;
