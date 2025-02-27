
WITH address_combined AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_combined ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cs.cs_order_number AS catalog_order_number
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    GROUP BY 
        ws.ws_order_number, cs.cs_order_number
),
sales_summary AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        sd.total_quantity,
        sd.total_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ss.full_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales < 100 THEN 'Low Spending'
        WHEN ss.total_sales BETWEEN 100 AND 500 THEN 'Medium Spending'
        ELSE 'High Spending'
    END AS spending_category
FROM 
    sales_summary ss
ORDER BY 
    ss.total_sales DESC;
