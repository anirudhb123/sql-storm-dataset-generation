
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 10000
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.order_count) AS total_orders
    FROM 
        high_value_customers cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.avg_sales,
    ds.total_orders,
    (SELECT COUNT(*) FROM customer) AS total_customers
FROM 
    demographic_summary ds
ORDER BY 
    ds.total_orders DESC;
