
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
CustomerReturnStats AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CombinedStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_profit, 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturnStats r ON c.c_customer_sk = r.sr_returning_customer_sk
    LEFT JOIN 
        RankedSales s ON c.c_current_cdemo_sk = s.web_site_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    c.total_returns,
    c.total_return_amount,
    c.total_profit,
    CASE 
        WHEN c.total_profit > 1000 THEN 'High Value Customer'
        WHEN c.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM 
    CombinedStats c
WHERE 
    c.total_returns IS NOT NULL AND 
    (c.total_profit IS NULL OR c.total_profit > 0)
ORDER BY 
    c.total_profit DESC, c.c_last_name ASC;
