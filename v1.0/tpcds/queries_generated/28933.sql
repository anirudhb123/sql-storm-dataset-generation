
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS registration_date,
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
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_customer_sk
),
FilteredCustomerSales AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_customer_sk
    WHERE 
        ci.cd_gender = 'F' AND 
        (ci.cd_marital_status = 'M' OR ci.cd_marital_status = 'S') AND 
        ci.ca_state IN ('NY', 'CA')
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS avg_sales_per_customer,
    MAX(total_sales) AS max_sales
FROM 
    FilteredCustomerSales
GROUP BY 
    ca_state
ORDER BY 
    ca_state;
