
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
GroupedDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender
),
SalesStatistics AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    gd.cd_gender,
    gd.customer_count,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_net_paid, 0) AS total_net_paid
FROM AddressInfo ai
JOIN GroupedDemographics gd ON gd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ai.ca_address_sk)
LEFT JOIN SalesStatistics ss ON ss.ws_bill_cdemo_sk = gd.cd_demo_sk
WHERE ai.ca_state = 'CA'
ORDER BY ai.ca_city, gd.cd_gender;
