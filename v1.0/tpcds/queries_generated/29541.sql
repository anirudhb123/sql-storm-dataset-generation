
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        UPPER(ca_country) AS upper_country
    FROM 
        customer_address
),
demographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_profile
    FROM 
        customer_demographics
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.upper_country,
        d.demographic_profile,
        ss.total_sales,
        ss.avg_net_profit
    FROM 
        processed_addresses ca
    LEFT JOIN 
        demographics d ON d.cd_demo_sk = (
            SELECT cd_demo_sk FROM customer WHERE c_customer_sk = ca.ca_address_sk
        )
    LEFT JOIN 
        sales_summary ss ON ss.ws_bill_customer_sk = ca.ca_address_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High' 
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium' 
        ELSE 'Low' 
    END AS sales_category
FROM 
    final_report
WHERE 
    UPPER(upper_country) = 'USA'
ORDER BY 
    total_sales DESC;
