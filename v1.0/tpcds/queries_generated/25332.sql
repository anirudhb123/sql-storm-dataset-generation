
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
customer_benchmark AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        ss.total_sales,
        ss.orders_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.bill_customer_sk
    WHERE 
        ss.total_sales IS NOT NULL OR ss.orders_count IS NOT NULL
)
SELECT 
    full_name,
    c_email_address,
    ca_city,
    ca_state,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(orders_count, 0) AS orders_count,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales Activity'
        WHEN total_sales < 1000 THEN 'Low'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM 
    customer_benchmark
ORDER BY 
    total_sales DESC;
