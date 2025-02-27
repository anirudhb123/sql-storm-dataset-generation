
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        s.ws_sold_date_sk,
        SUM(s.ws_quantity) + cte.total_quantity,
        SUM(s.ws_net_profit) + cte.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ws_sold_date_sk ORDER BY SUM(s.ws_net_profit) DESC) AS rn
    FROM 
        web_sales s 
    JOIN 
        SalesCTE cte ON s.ws_sold_date_sk = cte.ws_sold_date_sk
    WHERE 
        cte.rn < 10
    GROUP BY 
        s.ws_sold_date_sk, cte.total_quantity, cte.total_net_profit
),
TopSales AS (
    SELECT 
        ws_sold_date_sk,
        total_quantity,
        total_net_profit
    FROM 
        SalesCTE
    WHERE 
        rn <= 5
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS total_return_records
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerTotals AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
    LEFT JOIN 
        (SELECT 
             ws_bill_customer_sk,
             SUM(ws_net_profit) AS total_net_profit
         FROM 
             web_sales
         GROUP BY 
             ws_bill_customer_sk) rs ON c.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    ct.c_first_name,
    ct.c_last_name,
    ct.total_returns,
    ROUND(ct.total_net_profit, 2) AS total_net_profit,
    ts.total_quantity,
    ts.total_net_profit AS top_net_profit
FROM 
    CustomerTotals ct
LEFT JOIN 
    TopSales ts ON ts.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE 
    ct.total_net_profit > 0
ORDER BY 
    ct.total_net_profit DESC, ct.total_returns DESC;
