
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        ranked_customers
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.total_sales,
    tc.order_count,
    d.d_year,
    d.d_month_seq
FROM 
    top_customers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, tc.order_count DESC;
