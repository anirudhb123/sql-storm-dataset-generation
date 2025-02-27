
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_qty) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_returns,
        r.total_return_qty,
        r.total_return_amt,
        ROW_NUMBER() OVER (ORDER BY r.total_return_amt DESC) AS rn
    FROM 
        customer c
    JOIN 
        CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
    WHERE 
        r.total_return_qty IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_profit, 0) AS total_profit,
    tc.total_returns,
    tc.total_return_qty,
    tc.total_return_amt
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.customer_id
WHERE 
    tc.rn <= 10
ORDER BY 
    total_profit DESC;
