
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_profit > 1000
    UNION ALL
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        CustomerSales cs
    JOIN 
        store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name
    HAVING 
        total_profit > 1000
),
ProfitStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS net_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_month = 12
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RecentReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    p.c_first_name,
    p.c_last_name,
    p.total_orders,
    p.net_profit,
    r.total_returns,
    r.total_return_amt,
    (CASE WHEN p.net_profit IS NULL THEN 0 ELSE p.net_profit END) - COALESCE(r.total_return_amt, 0) AS profit_after_returns
FROM 
    ProfitStats p
LEFT JOIN 
    RecentReturns r ON r.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
WHERE 
    p.profit_rank <= 10
ORDER BY 
    profit_after_returns DESC
