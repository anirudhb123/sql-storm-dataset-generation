
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS hierarchy_level
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_net_profit
    FROM SalesData sd
    WHERE sd.profit_rank <= 10
),
ReturnStatistics AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
        CASE 
            WHEN COALESCE(rs.total_returns, 0) > 0 THEN 'Returns Applicable'
            ELSE 'No Returns'
        END AS return_status
    FROM CustomerHierarchy ci
    CROSS JOIN TopItems ti
    LEFT JOIN ReturnStatistics rs ON ti.ws_item_sk = rs.sr_item_sk
)

SELECT 
    *,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CONCAT(c_first_name, ' ', c_last_name) AS full_customer_name
FROM FinalReport
WHERE return_status = 'Returns Applicable'
ORDER BY total_net_profit DESC;
