
WITH AddressStats AS (
    SELECT 
        ca_city,
        UPPER(ca_street_name) AS upper_street_name,
        LENGTH(ca_street_name) AS street_length,
        COUNT(DISTINCT ca_address_id) AS address_count
    FROM customer_address
    GROUP BY ca_city, ca_street_name
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status, cd_education_status
),
SalesStats AS (
    SELECT 
        SUM(CASE WHEN ws_item_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_item_sk IS NOT NULL THEN cs_quantity ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss_item_sk IS NOT NULL THEN ss_quantity ELSE 0 END) AS total_store_sales
    FROM web_sales
    FULL OUTER JOIN catalog_sales ON ws_item_sk = cs_item_sk
    FULL OUTER JOIN store_sales ON ws_item_sk = ss_item_sk
)
SELECT 
    a.ca_city,
    a.upper_street_name, 
    a.street_length,
    a.address_count,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.total_dependents,
    c.avg_purchase_estimate,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales
FROM AddressStats a
JOIN CustomerDemographics c ON a.address_count > 5
JOIN SalesStats s ON s.total_web_sales > 1000 OR s.total_catalog_sales > 1000 OR s.total_store_sales > 1000
WHERE a.street_length > 10
ORDER BY a.ca_city, c.cd_gender;
