
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND ws.ws_net_profit > 0
),
TotalSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
RecentReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_returned_date_sk, wr.wr_returning_customer_sk
)
SELECT 
    cs.c_customer_id,
    COALESCE(tr.total_profit, 0) AS total_profit,
    COALESCE(rr.total_returns, 0) AS total_returns,
    CASE 
        WHEN tr.total_profit > 1000 THEN 'High Value Customer'
        WHEN tr.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    TotalSales tr
LEFT JOIN 
    RecentReturns rr ON tr.c_customer_id = rr.wr_returning_customer_sk
JOIN 
    RankedSales cs ON cs.c_customer_id = tr.c_customer_id
WHERE 
    cs.rn = 1
ORDER BY 
    total_profit DESC, total_returns DESC;
