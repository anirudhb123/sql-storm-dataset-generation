
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_value
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_value > (
            SELECT 
                AVG(total_return_value) 
            FROM 
                CustomerReturns
        )
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales_value,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    r.total_sales_value,
    r.order_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentSales r ON hvc.sr_customer_sk = r.ws_bill_customer_sk
ORDER BY 
    r.total_sales_value DESC
LIMIT 10;
