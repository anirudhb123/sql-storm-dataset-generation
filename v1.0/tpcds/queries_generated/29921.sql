
WITH address_data AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
        CASE 
            WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) 
            ELSE '' 
        END)) AS full_address,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(ca.ca_zip FROM 1 FOR 5) AS zip_prefix
    FROM 
        customer_address ca
),
demographics_data AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        INITCAP(cd.cd_education_status) AS education_level,
        cd.cd_purchase_estimate,
        LEAST(cd.cd_dep_count, 5) AS max_dependents
    FROM 
        customer_demographics cd
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    de.education_level,
    de.max_dependents,
    sd.total_quantity_sold,
    sd.total_sales,
    STRING_AGG(CONCAT(de.max_dependents, ' dependents (', de.cd_gender, ')'), ', ') AS dependent_details
FROM 
    address_data ad
JOIN 
    demographics_data de ON de.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_addr_sk = ad.ca_address_sk LIMIT 1)
JOIN 
    sales_data sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_id = 'ITEM_ID' LIMIT 5)
GROUP BY 
    ad.full_address, ad.ca_city, ad.ca_state, de.education_level, de.max_dependents
ORDER BY 
    ad.ca_state, total_sales DESC
LIMIT 100;
