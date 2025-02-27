
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
CombinedData AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        SalesData sd ON cr.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_net_profit = 0 THEN NULL 
        ELSE (total_return_amount / total_net_profit) END AS return_ratio
FROM 
    CombinedData
WHERE 
    (total_returns > 0 OR total_quantity_sold > 0)
    AND (total_return_amount > 100 OR return_ratio IS NOT NULL)
ORDER BY 
    return_ratio DESC NULLS LAST
LIMIT 100;
