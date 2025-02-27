
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
DailySales AS (
    SELECT 
        ws_bill_customer_sk,
        d.d_date,
        SUM(ws_sales_price) AS daily_sales_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, d.d_date
),
SalesRank AS (
    SELECT 
        ws_bill_customer_sk,
        d.d_date,
        daily_sales_value,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY daily_sales_value DESC) AS sales_rank
    FROM 
        DailySales
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(CR.total_returned_quantity, 0) AS total_returns,
    COALESCE(CR.total_return_amount, 0) AS total_return_amount,
    COALESCE(SR.daily_sales_value, 0) AS highest_daily_sales_value,
    S.sales_rank
FROM 
    customer c
LEFT JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.cr_returning_customer_sk
LEFT JOIN 
    SalesRank SR ON c.c_customer_sk = SR.ws_bill_customer_sk AND SR.sales_rank = 1
WHERE 
    COALESCE(CR.total_returned_quantity, 0) > 0 OR 
    (SR.daily_sales_value IS NULL AND EXISTS (
        SELECT 
            1 
        FROM 
            web_sales low_sales 
        WHERE 
            low_sales.ws_bill_customer_sk = c.c_customer_sk 
            AND low_sales.ws_sales_price < (SELECT AVG(ws_sales_price) * 0.5 FROM web_sales)
    ))
ORDER BY 
    c.c_last_name, c.c_first_name;
