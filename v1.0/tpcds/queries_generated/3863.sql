
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amount) DESC) AS rn
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amount
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE 
        cr.total_returns > 5
)
SELECT 
    hrc.c_customer_id,
    hrc.total_returns,
    hrc.total_return_amount,
    COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_sales_value, 0) AS total_sales_value
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    SalesData sd ON hrc.c_customer_id = sd.ws_item_sk
WHERE 
    hrc.total_return_amount > 500
ORDER BY 
    hrc.total_return_amount DESC
LIMIT 10;
