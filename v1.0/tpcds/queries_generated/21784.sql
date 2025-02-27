
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), 
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit
    FROM RankedSales rs
    WHERE rs.profit_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_count.customer_sk,
        SUM(COALESCE(sr.return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(sr.return_amt, 0)) AS total_return_amount
    FROM (
        SELECT DISTINCT sr_customer_sk AS customer_sk FROM store_returns
        UNION ALL
        SELECT DISTINCT wr_returning_customer_sk AS customer_sk FROM web_returns
    ) AS sr_count
    LEFT JOIN store_returns sr ON sr_count.customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON sr_count.customer_sk = wr.wr_returning_customer_sk
    GROUP BY sr_count.customer_sk
),
FinalResults AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        hpi.total_quantity,
        hpi.total_net_profit,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(cr.total_return_quantity, 0) > 0 THEN 'Returns'
            ELSE 'No Returns' 
        END AS return_status
    FROM customer ci
    JOIN HighProfitItems hpi ON ci.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_item_sk = hpi.ws_item_sk LIMIT 1)
    LEFT JOIN CustomerReturns cr ON ci.c_customer_sk = cr.customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(f.total_net_profit) AS total_net_profit_sum,
    COUNT(DISTINCT f.return_status) AS distinct_return_statuses,
    CASE 
        WHEN SUM(f.total_return_amount) IS NULL OR SUM(f.total_return_amount) = 0 THEN 'No Returns' 
        ELSE 'Has Returns' 
    END AS overall_return_status
FROM FinalResults f
JOIN customer c ON f.c_customer_id = c.c_customer_id 
WHERE (c.c_birth_year < 1980 OR c.c_marital_status = 'M') 
GROUP BY c.c_first_name, c.c_last_name
HAVING total_net_profit_sum > 1000
ORDER BY total_net_profit_sum DESC
LIMIT 10 OFFSET (SELECT COUNT(*) / 2 FROM customer);
