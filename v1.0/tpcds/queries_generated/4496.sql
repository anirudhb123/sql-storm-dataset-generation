
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_return_quantity, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
DetailedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returned_date_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_tax,
        COALESCE(c.c_first_name, 'Unknown') AS first_name,
        COALESCE(c.c_last_name, 'Unknown') AS last_name,
        ca.ca_city
    FROM 
        catalog_returns cr
    LEFT JOIN 
        customer c ON cr.returning_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
) 
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(CR.total_return_quantity, 0) AS total_returned_items,
    COALESCE(S.total_orders, 0) AS total_orders,
    COALESCE(S.total_sales, 0.00) AS total_sales,
    COALESCE(DR.return_quantity, 0) AS last_catalog_return_qty,
    COALESCE(DR.return_amount, 0.00) AS last_catalog_return_amt,
    DATEDIFF(NOW(), MAX(DR.returned_date_sk)) AS days_since_last_return
FROM 
    customer c 
LEFT JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
LEFT JOIN 
    DetailedReturns DR ON c.c_customer_sk = DR.returning_customer_sk
LEFT JOIN 
    SalesStats S ON c.c_customer_sk = S.ws_bill_customer_sk
WHERE 
    c.c_birth_year < 2000
ORDER BY 
    total_returned_items DESC, 
    total_sales DESC
LIMIT 50;
