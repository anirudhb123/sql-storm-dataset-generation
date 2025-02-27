
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(wr_order_number) AS return_count,
        AVG(wr_return_amt_inc_tax) AS avg_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ISNULL(cr.total_returns, 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE 
        cr.total_returns > 0
)
SELECT 
    t1.ws_item_sk,
    SUM(t1.ws_quantity) AS total_quantity_sold,
    SUM(t1.ws_net_profit) AS total_net_profit,
    tc.total_returns,
    COALESCE(t1.average_return_value, 0) AS average_return_value
FROM 
    RankedSales t1
LEFT JOIN 
    TopCustomers tc ON t1.ws_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_bill_customer_sk = tc.c_customer_sk)
LEFT JOIN 
    (SELECT 
        wr_returning_customer_sk, 
        AVG(wr_return_amt_inc_tax) AS average_return_value 
     FROM 
        web_returns 
     GROUP BY 
        wr_returning_customer_sk) t2 ON tc.wr_returning_customer_sk = t2.wr_returning_customer_sk
WHERE 
    t1.rnk = 1
GROUP BY 
    t1.ws_item_sk, tc.total_returns, t1.average_return_value
HAVING 
    total_net_profit > 1000
ORDER BY 
    total_net_profit DESC;
