
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_state ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 5
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
    (tc.total_sales - COALESCE(SUM(sr.sr_return_amt), 0)) AS net_sales
FROM 
    top_customers tc
LEFT JOIN 
    store_returns sr ON tc.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales
ORDER BY 
    net_sales DESC
LIMIT 10;
