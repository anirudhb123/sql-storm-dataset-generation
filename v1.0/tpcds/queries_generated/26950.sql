
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        dc.d_year AS year_of_birth
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dc ON c.c_birth_year = dc.d_year
),
Sales_Info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Final_Benchmark AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.year_of_birth,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        COALESCE(si.total_spent, 0) AS total_spent,
        COALESCE(si.order_count, 0) AS order_count
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Address_Concat a ON ci.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        Sales_Info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value Customer'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    Final_Benchmark
ORDER BY 
    total_spent DESC;
