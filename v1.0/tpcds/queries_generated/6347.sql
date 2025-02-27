
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.last_purchase_date,
    d.d_year,
    d.d_month_seq,
    COUNT(ws.ws_order_number) AS additional_order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    date_dim d ON d.d_date_sk = tc.last_purchase_date
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_id
WHERE 
    tc.sales_rank <= 50
GROUP BY 
    tc.c_customer_id, tc.total_sales, tc.order_count, tc.last_purchase_date, d.d_year, d.d_month_seq
ORDER BY 
    tc.total_sales DESC;
