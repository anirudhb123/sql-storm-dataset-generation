
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    CASE 
        WHEN tc.order_count > 10 THEN 'Frequent'
        WHEN tc.total_sales > 1000 THEN 'High Value'
        ELSE 'Standard'
    END AS customer_segment,
    COALESCE(t.date, '2023-10-01') AS last_order_date,
    d.d_year,
    COUNT(DISTINCT ws.ws_ship_mode_sk) AS unique_ship_modes
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk, MAX(d_date) AS date
     FROM 
        web_sales
     JOIN 
        date_dim ON ws_bill_customer_sk = ws_bill_customer_sk
     GROUP BY 
        ws_bill_customer_sk) t ON tc.c_customer_sk = t.ws_bill_customer_sk
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.total_sales DESC
LIMIT 50;
