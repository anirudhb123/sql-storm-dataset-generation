
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        REPLACE(ca_country, ' ', '_') AS sanitized_country
    FROM customer_address
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        CONCAT(cd_education_status, ' - ', cd_credit_rating) AS education_and_credit
    FROM customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ad.ca_zip,
        ad.sanitized_country,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.education_and_credit,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN DemographicDetails dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.state,
    c.full_address,
    c.zip,
    c.sanitized_country,
    c.gender,
    c.marital_status,
    c.education_and_credit,
    c.total_sales,
    c.order_count,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value Customer'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_segment
FROM CustomerAnalysis c
WHERE c.total_sales > 0
ORDER BY c.total_sales DESC, c.last_name ASC
LIMIT 100;
