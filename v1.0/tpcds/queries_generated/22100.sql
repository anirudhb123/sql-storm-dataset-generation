
WITH RankedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY cr_item_sk ORDER BY SUM(cr_return_quantity) DESC) AS return_rank
    FROM catalog_returns
    GROUP BY cr_item_sk
),
NetProfits AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_item_sk
),
CustomerInsights AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        COUNT(DISTINCT cr_returning_customer_sk) AS total_returns,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(COALESCE(c_birth_day, 0)) AS total_birth_days_collected
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN catalog_returns ON cr_returning_customer_sk = c_customer_sk
    GROUP BY c_customer_sk, cd_gender
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    COALESCE(rr.total_returned, 0) AS total_returns,
    np.total_net_profit,
    ci.total_birth_days_collected,
    CASE 
        WHEN ci.total_returns > 50 THEN 'Frequent Returner'
        WHEN ci.total_returns BETWEEN 20 AND 50 THEN 'Moderate Returner'
        ELSE 'Rare Returner'
    END AS return_category,
    CASE 
        WHEN np.total_net_profit IS NULL THEN 'Check Data'
        ELSE CONCAT('Profit: $', FORMAT(np.total_net_profit, 2))
    END AS profit_report
FROM CustomerInsights ci
LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.cr_item_sk
FULL OUTER JOIN NetProfits np ON rr.cr_item_sk = np.ws_item_sk
WHERE ci.avg_dependents IS NOT NULL 
  AND rr.total_returned > 0
  AND (np.total_net_profit IS NULL OR np.total_net_profit > 1000)
ORDER BY ci.cd_gender, return_category DESC;
