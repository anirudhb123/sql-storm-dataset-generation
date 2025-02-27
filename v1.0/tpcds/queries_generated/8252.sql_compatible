
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 1500
    GROUP BY 
        c.c_customer_sk, c.c_gender, cd.cd_marital_status, cd.cd_education_status
),
demographics_summary AS (
    SELECT 
        c_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales,
        AVG(total_sales) AS avg_sales_per_customer,
        AVG(order_count) AS avg_orders_per_customer,
        AVG(avg_order_value) AS avg_order_value
    FROM 
        customer_sales
    GROUP BY 
        c_gender, cd_marital_status, cd_education_status
)
SELECT 
    c_gender,
    cd_marital_status,
    cd_education_status,
    customer_count,
    total_sales,
    avg_sales_per_customer,
    avg_orders_per_customer,
    avg_order_value
FROM 
    demographics_summary
WHERE 
    customer_count > 10
ORDER BY 
    total_sales DESC;
