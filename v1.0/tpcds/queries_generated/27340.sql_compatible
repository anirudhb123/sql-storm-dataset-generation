
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
        cs_bill_customer_sk,
        COUNT(cs_order_number) AS total_orders,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        si.total_orders,
        si.total_sales
    FROM 
        customer_info ci
    JOIN 
        sales_summary si ON ci.c_customer_id = si.cs_bill_customer_sk
    ORDER BY 
        si.total_sales DESC
    LIMIT 10
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank,
    full_name,
    ca_city,
    total_orders,
    total_sales
FROM 
    top_customers;
