
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_zip) AS zip_length,
        TRIM(BOTH ' ' FROM ca_suite_number) AS suite_number
    FROM 
        customer_address
),
DemoInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS edu_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_combo
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws.item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.item_sk
)
SELECT 
    A.full_address,
    A.city,
    A.state,
    D.edu_status,
    D.gender_marital_combo,
    S.total_sales,
    S.order_count,
    S.avg_net_profit
FROM 
    AddressInfo A
JOIN 
    DemoInfo D ON D.cd_demo_sk = A.ca_address_sk  -- assuming a hypothetical join condition
LEFT JOIN 
    SalesInfo S ON S.item_sk = A.ca_address_sk  -- assuming item_sk as a stand-in for address index
WHERE 
    A.zip_length BETWEEN 5 AND 10
ORDER BY 
    S.total_sales DESC, A.city, D.gender_marital_combo;
