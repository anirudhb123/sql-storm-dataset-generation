
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE ca_city LIKE 'S%'
),
CustomerStatistics AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT 
    ad.ca_address_sk,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    cs.customer_count,
    cs.avg_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM AddressDetails ad
LEFT JOIN CustomerStatistics cs ON cs.cd_demo_sk IN (
    SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F'
)
LEFT JOIN SalesData sd ON sd.ws_bill_cdemo_sk = cs.cd_demo_sk
ORDER BY ad.ca_city, ad.ca_state, ad.ca_zip;
