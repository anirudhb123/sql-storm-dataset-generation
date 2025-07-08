
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.sales_rank,
    da.ca_city,
    da.ca_state,
    dc.d_year,
    dc.d_month_seq
FROM 
    TopCustomers tc
JOIN 
    customer_address da ON tc.c_customer_sk = da.ca_address_sk
JOIN 
    date_dim dc ON dc.d_date_sk = (SELECT MIN(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank <= 10 AND
    da.ca_state = 'CA'
ORDER BY 
    tc.total_sales DESC, 
    tc.order_count DESC;
