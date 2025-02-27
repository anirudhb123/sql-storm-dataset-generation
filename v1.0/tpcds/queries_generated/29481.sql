
WITH formatted_addresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(', Suite ', ca_suite_number) 
                    ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address 
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL 
),
demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
date_summary AS (
    SELECT 
        d_month_seq, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_month_seq
),
combined_summary AS (
    SELECT 
        fa.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        ds.order_count,
        ds.total_sales
    FROM 
        formatted_addresses fa
    JOIN 
        demographics d ON d.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = fa.full_address LIMIT 1)
    JOIN 
        date_summary ds ON ds.d_month_seq = (SELECT EXTRACT(MONTH FROM CURRENT_DATE))
)
SELECT 
    full_address, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    order_count, 
    total_sales 
FROM 
    combined_summary
ORDER BY 
    total_sales DESC, 
    order_count DESC 
LIMIT 100;
