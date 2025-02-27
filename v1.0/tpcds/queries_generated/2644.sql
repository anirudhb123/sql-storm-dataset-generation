
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3 LIMIT 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_amt_inc_tax) AS total_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
FinalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        cs.total_sales - COALESCE(cr.total_returned, 0) AS net_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        CustomerReturns cr ON cs.c_customer_id = cr.returning_customer_sk
)
SELECT 
    fs.c_customer_id,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_sales,
    fs.total_returned,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales >= 1000 THEN 'High Value'
        WHEN fs.net_sales >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    FinalSales fs
WHERE 
    fs.sales_rank <= 10
ORDER BY 
    fs.net_sales DESC;
