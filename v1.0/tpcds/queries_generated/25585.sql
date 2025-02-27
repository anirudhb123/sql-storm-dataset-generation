
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        c.customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer_info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.customer_sk
),
analytics AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 1000 THEN 'High Spender'
        WHEN total_sales > 500 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    analytics
WHERE 
    LOWER(cd_gender) = 'f' 
    AND ca_state IN ('CA', 'NY')
ORDER BY 
    total_sales DESC
LIMIT 100;
