
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
              CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemoData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws_ext_sales_price,
        ws_quantity,
        ws_net_profit,
        A.full_address,
        D.cd_gender,
        D.cd_marital_status
    FROM web_sales AS ws
    JOIN AddressData AS A ON ws.ws_ship_addr_sk = A.ca_address_sk
    JOIN DemoData AS D ON ws.ws_bill_cdemo_sk = D.cd_demo_sk
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    COUNT(*) AS number_of_sales,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_quantity) AS avg_quantity_sold
FROM SalesData
WHERE ca_state = 'CA' AND cd_gender = 'M'
GROUP BY full_address, cd_gender, cd_marital_status
ORDER BY total_sales DESC
LIMIT 10;
