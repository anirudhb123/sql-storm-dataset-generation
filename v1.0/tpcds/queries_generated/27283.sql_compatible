
WITH AddressDetails AS (
    SELECT 
        ca_address_id, 
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, ''), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDemo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        LEAST(cd_dep_count, cd_dep_employed_count, cd_dep_college_count) AS minimum_dependents
    FROM customer_demographics
),
SalesData AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales,
        cs_bill_customer_sk,
        cs_ship_customer_sk
    FROM web_sales
    JOIN catalog_sales ON web_sales.ws_order_number = catalog_sales.cs_order_number
    GROUP BY cs_bill_customer_sk, cs_ship_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    cd.cd_gender,
    cd.minimum_dependents,
    COALESCE(sd.total_sales, 0) AS total_sales_value
FROM customer c
JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_id
JOIN CustomerDemo cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN SalesData sd ON c.c_customer_sk = sd.cs_bill_customer_sk OR c.c_customer_sk = sd.cs_ship_customer_sk
WHERE cd.cd_gender = 'M'
AND cd.minimum_dependents > 0
ORDER BY total_sales_value DESC, c.c_last_name, c.c_first_name;
