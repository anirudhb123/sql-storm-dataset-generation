
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amt DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returns > 0
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    si.total_profit,
    si.order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesInfo si ON tc.c_customer_id = si.ws_bill_customer_sk
WHERE 
    tc.rnk <= 10
  AND 
    (si.total_profit IS NULL OR si.total_profit > 0)
ORDER BY 
    tc.cd_gender, tc.cd_marital_status, si.total_profit DESC;
