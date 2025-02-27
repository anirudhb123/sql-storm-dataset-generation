
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
CombinedSales AS (
    SELECT 
        hpi.ws_item_sk,
        hpi.ws_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(cr.total_return_amt, 0) = 0 THEN hpi.ws_net_profit
            ELSE hpi.ws_net_profit / NULLIF(cr.total_return_amt, 0) 
        END AS adjusted_profit
    FROM 
        HighProfitItems hpi
    LEFT JOIN 
        CustomerReturns cr ON hpi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    cs.ws_item_sk,
    cs.ws_net_profit,
    cs.total_returns,
    cs.adjusted_profit,
    CASE 
        WHEN cs.adjusted_profit > 100 THEN 'High Profit'
        WHEN cs.adjusted_profit BETWEEN 50 AND 100 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    customer ci
JOIN 
    web_sales cs ON ci.c_customer_sk = cs.ws_bill_customer_sk
WHERE 
    cs.ws_net_profit IS NOT NULL
AND 
    cs.ws_item_sk IN (SELECT ws_item_sk FROM CombinedSales) 
AND 
    ci.c_current_cdemo_sk IS NOT NULL
UNION ALL
SELECT 
    NULL AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    cs.ws_item_sk,
    SUM(cs.ws_net_profit) AS total_net_profit,
    SUM(cs.total_returns) AS total_returns,
    0 AS adjusted_profit,
    'Aggregate Profit' AS profit_category
FROM 
    CombinedSales cs
GROUP BY 
    cs.ws_item_sk
HAVING 
    SUM(cs.ws_net_profit) > 1000
ORDER BY 
    profit_category, total_net_profit DESC;
