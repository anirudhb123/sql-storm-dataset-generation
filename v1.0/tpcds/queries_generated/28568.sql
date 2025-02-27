
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, 'No Number'), ' ', COALESCE(ca_street_name, 'Unknown'), ' ', COALESCE(ca_street_type, 'ST')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        UPPER(cd_gender) AS gender,
        INITCAP(cd_marital_status) AS marital_status,
        LEFT(cd_education_status, 4) AS edu_short
    FROM customer_demographics
),
SalesDetails AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.web_site_id
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.gender,
    d.marital_status,
    d.edu_short,
    s.total_sales,
    s.order_count
FROM AddressDetails a
JOIN DemographicDetails d ON a.ca_address_sk = d.cd_demo_sk
JOIN SalesDetails s ON s.web_site_id = (SELECT web_site_id FROM web_site LIMIT 1)
WHERE a.ca_country = 'USA' 
AND s.total_sales > 1000
ORDER BY s.total_sales DESC, a.ca_city ASC;
