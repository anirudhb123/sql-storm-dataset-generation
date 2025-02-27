
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_desc,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_dep_count, 0) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.ws_bill_customer_sk
),
BenchmarkResults AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.gender_desc,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.total_dependents,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 'No Purchases'
            WHEN COALESCE(rs.total_sales, 0) > 500 THEN 'High Value'
            ELSE 'Regular Customer'
        END AS customer_segment
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RecentSales rs ON ci.c_customer_id = rs.ws_bill_customer_sk
)
SELECT 
    *,
    CONCAT('Customer: ', full_name, ' | Total Sales: $', ROUND(total_sales, 2), ' | Segment: ', customer_segment) AS descriptive_summary
FROM 
    BenchmarkResults
ORDER BY 
    total_sales DESC
LIMIT 100;
