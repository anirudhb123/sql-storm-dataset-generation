
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(DISTINCT sr_returning_customer_sk) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) AND 
        sr_returned_date_sk <= (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        sr_returned_date_sk
),
SalesData AS (
    SELECT 
        d.d_date_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date_sk
)
SELECT 
    d.d_date_sk,
    d.d_date,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
    (COALESCE(sd.total_sales_amount, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales
FROM 
    date_dim d
LEFT JOIN 
    CustomerReturns cr ON d.d_date_sk = cr.sr_returned_date_sk
LEFT JOIN 
    SalesData sd ON d.d_date_sk = sd.d_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date_sk;
