
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 1000 AND 2000
),
TotalReturns AS (
    SELECT 
        wr.web_site_sk,
        SUM(wr.return_amt) AS total_return_amt,
        COUNT(wr.returning_customer_sk) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.web_site_sk
),
SalesAndReturns AS (
    SELECT 
        r.web_site_sk,
        r.total_return_amt,
        s.net_profit
    FROM 
        TotalReturns r
    LEFT JOIN 
        RankedSales s ON r.web_site_sk = s.web_site_sk
    WHERE 
        r.total_return_amt IS NOT NULL AND 
        (r.total_return_amt > 100 OR s.net_profit IS NULL)
)
SELECT 
    COALESCE(ws.web_site_name, 'N/A') AS website_name,
    COALESCE(SUM(sar.net_profit), 0) AS total_net_profit,
    COALESCE(SUM(sar.total_return_amt), 0) AS total_returns,
    CASE 
        WHEN SUM(sar.net_profit) > 0 THEN 'Profitable'
        WHEN SUM(sar.total_return_amt) > 0 AND SUM(sar.net_profit) = 0 THEN 'Zero Profit with Returns'
        ELSE 'Loss'
    END AS profitability_status,
    EXISTS (
        SELECT 
            1 
        FROM 
            store s 
        WHERE 
            s.store_id = '9999999999999999'
    ) AS has_missing_store
FROM 
    SalesAndReturns sar
LEFT JOIN 
    web_site ws ON sar.web_site_sk = ws.web_site_sk
GROUP BY 
    ws.web_site_name
HAVING 
    SUM(sar.net_profit) > AVG(sar.total_return_amt) OR COUNT(*) > 0
ORDER BY 
    total_net_profit DESC, total_returns ASC;
