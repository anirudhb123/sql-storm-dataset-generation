
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year > 1980
),
sales_summary AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
),
gender_sales AS (
    SELECT 
        ci.cd_gender,
        COUNT(*) AS total_customers,
        SUM(ss.total_sales) AS total_sales_by_gender,
        AVG(ss.avg_order_value) AS avg_order_value_by_gender
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_id = ss.web_site_id
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.total_customers,
    gs.total_sales_by_gender,
    gs.avg_order_value_by_gender,
    RANK() OVER (ORDER BY gs.total_sales_by_gender DESC) AS sales_rank
FROM 
    gender_sales gs
ORDER BY 
    gs.total_sales_by_gender DESC;
