
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.total_sales,
        c.order_count,
        c.avg_order_value,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        customer_summary c
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.avg_order_value,
    DENSE_RANK() OVER (PARTITION BY cd.cd_education_status ORDER BY tc.total_sales DESC) AS education_rank
FROM 
    top_customers tc
JOIN
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
WHERE
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, 
    education_rank;
