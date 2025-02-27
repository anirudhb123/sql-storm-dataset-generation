
WITH address_analysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CAST(ca_zip AS VARCHAR)) AS zip_length,
        LOWER(ca_city) AS city_lower,
        COUNT(*) OVER (PARTITION BY ca_country) AS country_count
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'TX', 'NY')
),
demographics_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        REPLACE(cd_education_status, ' ', '_') AS education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer_demographics
),
sales_combined AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
final_report AS (
    SELECT 
        aa.full_address,
        da.cd_gender,
        da.education_status,
        sa.total_sales,
        sa.order_count,
        sa.total_quantity,
        aa.country_count
    FROM 
        address_analysis aa
    JOIN 
        demographics_analysis da ON da.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = aa.ca_address_sk LIMIT 1)
    JOIN 
        sales_combined sa ON sa.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = aa.ca_address_sk LIMIT 1) LIMIT 1)
)
SELECT 
    full_address,
    cd_gender,
    education_status,
    total_sales,
    order_count,
    total_quantity,
    country_count
FROM 
    final_report
ORDER BY 
    total_sales DESC
LIMIT 10;
