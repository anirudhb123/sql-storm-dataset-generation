
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 10
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(tc.total_sales) AS avg_sales,
        AVG(tc.order_count) AS avg_orders
    FROM 
        top_customers tc
    JOIN 
        customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.avg_sales,
    da.avg_orders,
    COUNT(*) OVER () AS total_segments
FROM 
    demographic_analysis da
ORDER BY 
    da.avg_sales DESC, 
    da.cd_gender, 
    da.cd_marital_status;
