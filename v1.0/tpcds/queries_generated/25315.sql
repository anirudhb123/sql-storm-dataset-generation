
WITH AddressDetails AS (
    SELECT 
        ca_state,
        CA_COUNTRY,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        COUNT(ca_address_sk) AS address_count,
        SUM(CASE WHEN ca_city LIKE '%Spring%' THEN 1 ELSE 0 END) AS spring_addresses
    FROM customer_address
    GROUP BY ca_state, ca_country
),
CustomerDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUBSTRING(cd_education_status, 1, 5) AS short_education,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ad.ca_state,
    ad.ca_country,
    ad.full_address,
    ad.address_count,
    ad.spring_addresses,
    cd.gender,
    cd.marital_status,
    cd.short_education,
    cd.customer_count,
    sd.total_sales,
    sd.order_count
FROM AddressDetails ad
JOIN CustomerDetails cd ON ad.address_count > 10
JOIN SalesDetails sd ON cd.cd_demo_sk = sd.ws_bill_customer_sk
WHERE ad.address_count > 5 AND sd.total_sales > 1000
ORDER BY ad.ca_state, ad.ca_country, sd.total_sales DESC;
