
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        c.customer_id, 
        COUNT(ws.ws_order_number) AS order_count, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN customer_info c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.customer_id
),
demographic_analysis AS (
    SELECT 
        ci.full_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_education_status, 
        ss.order_count, 
        ss.total_sales
    FROM 
        customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_id = ss.customer_id
)
SELECT 
    da.full_name,
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    COALESCE(da.order_count, 0) AS total_orders,
    COALESCE(da.total_sales, 0.00) AS total_sales,
    ROUND((COALESCE(da.total_sales, 0.00) / NULLIF(da.order_count, 0)), 2) AS avg_order_value
FROM 
    demographic_analysis da
ORDER BY 
    da.total_sales DESC, 
    da.full_name;
