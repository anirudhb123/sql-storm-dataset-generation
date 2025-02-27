
WITH CombinedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', 
            TRIM(ca_street_number), 
            TRIM(ca_street_name), 
            TRIM(ca_street_type), 
            COALESCE(TRIM(ca_suite_number), '')) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM customer_address
),
CustomerFullNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS state_address_count
    FROM CombinedAddresses
    GROUP BY ca_state
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cfn.full_name,
    cfn.cd_gender,
    cfn.cd_marital_status,
    ac.state_address_count,
    COALESCE(sd.total_sales, 0) AS total_sales,
    CONCAT(ca.city, ', ', ca.state, ' ', ca.zip) AS address_location
FROM CustomerFullNames cfn
LEFT JOIN AddressCounts ac ON ac.ca_state = (SELECT ca_state FROM CombinedAddresses WHERE ca_address_sk = cfn.c_customer_sk LIMIT 1)
LEFT JOIN SalesData sd ON sd.ws_bill_customer_sk = cfn.c_customer_sk
LEFT JOIN CombinedAddresses ca ON ca.ca_address_sk = cfn.c_customer_sk
WHERE cfn.cd_purchase_estimate > 500
ORDER BY total_sales DESC, cfn.full_name ASC
LIMIT 100;
