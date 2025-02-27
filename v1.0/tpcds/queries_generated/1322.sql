
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON c.c_customer_id = cr.c_customer_id
    WHERE 
        cr.total_returns > 5
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        hrc.c_customer_id,
        COALESCE(sd.total_profit, 0) AS total_profit,
        sd.order_count,
        hrc.total_returns
    FROM 
        HighReturnCustomers hrc
    LEFT JOIN 
        SalesData sd ON hrc.c_customer_id = sd.customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cm.total_profit,
    cm.order_count,
    cm.total_returns
FROM 
    CustomerMetrics cm
JOIN 
    customer c ON c.c_customer_id = cm.c_customer_id
WHERE 
    c.c_birth_year = (SELECT MAX(c2.c_birth_year) FROM customer c2 WHERE c2.c_customer_sk IS NOT NULL)
ORDER BY 
    cm.total_profit DESC
LIMIT 10;
