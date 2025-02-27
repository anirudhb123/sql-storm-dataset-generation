
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        MIN(sr_return_amt) AS min_return_amt,
        MAX(sr_return_amt) AS max_return_amt,
        CASE 
            WHEN AVG(sr_return_amt) IS NULL THEN 'No Returns'
            WHEN AVG(sr_return_amt) < 0 THEN 'Negative Returns'
            ELSE 'Positive Returns'
        END AS return_status
    FROM store_returns
    GROUP BY sr_customer_sk
), SalesSummary AS (
    SELECT 
        ws_ship_customer_sk, 
        AVG(ws_net_profit) AS avg_net_profit,
        SUM(ws_quantity) AS total_sales
    FROM web_sales
    GROUP BY ws_ship_customer_sk
), CombinedData AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, ss.ws_ship_customer_sk) AS customer_id,
        cr.total_returned,
        cr.return_count,
        ss.avg_net_profit,
        ss.total_sales,
        CASE 
            WHEN cr.total_returned IS NULL AND ss.total_sales IS NULL THEN 'No Activity'
            WHEN cr.total_returned > COALESCE(ss.total_sales, 0) THEN 'Return Heavy'
            ELSE 'Normal'
        END AS activity_level
    FROM CustomerReturns cr
    FULL OUTER JOIN SalesSummary ss ON cr.sr_customer_sk = ss.ws_ship_customer_sk
)

SELECT 
    customer_id,
    total_returned,
    return_count,
    avg_net_profit,
    total_sales,
    activity_level
FROM CombinedData
WHERE (total_returned > 5 OR avg_net_profit IS NOT NULL)
  AND (return_count < 10 OR total_sales IS NULL)
ORDER BY customer_id
LIMIT 100
OFFSET (SELECT COUNT(*) FROM CombinedData) / 10 * 5
UNION ALL
SELECT 
    'N/A' as customer_id,
    NULL AS total_returned,
    NULL AS return_count,
    NULL AS avg_net_profit,
    COALESCE(SUM(ws_quantity), 0) AS total_sales,
    'Aggregated Sales' AS activity_level
FROM web_sales
WHERE ws_ship_customer_sk IS NULL
HAVING SUM(ws_quantity) > 10000
ORDER BY total_sales DESC
LIMIT 50;
