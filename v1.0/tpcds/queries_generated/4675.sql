
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_bill_customer_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amount) AS total_returned_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, cr.total_returned_amt
HAVING 
    SUM(ws.ws_net_profit) IS NOT NULL
ORDER BY 
    total_net_profit DESC
LIMIT 100;
