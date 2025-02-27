
WITH Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Aggregate_Info AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.order_count, 0) AS order_count
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    a.full_name,
    a.ca_city,
    a.ca_state,
    a.cd_gender,
    a.cd_marital_status,
    a.cd_education_status,
    a.cd_purchase_estimate,
    a.total_sales,
    a.order_count,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value' 
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    Aggregate_Info a
WHERE 
    a.cd_gender = 'F' AND a.total_sales > 0
ORDER BY 
    a.total_sales DESC
LIMIT 50;
