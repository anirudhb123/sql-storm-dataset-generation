
WITH CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_gender
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer c
    JOIN 
        CustomerSalesCTE cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.first_name,
    tc.last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;

-- Calculate returns and shipping stats for each customer
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(sr.sr_returned_date_sk) AS return_count,
    COUNT(cr.cr_returned_date_sk) AS catalog_return_count,
    COUNT(wr.wr_returned_date_sk) AS web_return_count,
    SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    SUM(COALESCE(sr.sr_return_amt, 0), COALESCE(cr.cr_return_amount, 0), COALESCE(wr.wr_return_amt, 0)) > 100
ORDER BY 
    total_return_amount DESC;
