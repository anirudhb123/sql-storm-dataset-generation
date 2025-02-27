
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        dd.d_moy IN (11, 12) -- Last two months of the year
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    rd.c_demo_id,
    rd.c_demo_gender,
    rd.c_demo_income_band,
    w.web_name,
    w.web_open_date_sk
FROM 
    top_customers tc
JOIN 
    customer_demographics rd ON tc.c_customer_sk = rd.cd_demo_sk
JOIN 
    web_site w ON w.web_site_sk = tc.c_customer_sk
WHERE 
    tc.sales_rank <= 10; -- Get top 10 customers
