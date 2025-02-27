
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca.ca_address_sk,
        ai.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
),
SalesInfo AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders,
        COUNT(DISTINCT cs_item_sk) AS unique_items
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
FinalResult AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        si.total_profit,
        si.total_orders,
        si.unique_items,
        ci.full_address
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.customer_sk
    WHERE ci.cd_purchase_estimate > 1000
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_profit,
    total_orders,
    unique_items,
    full_address
FROM FinalResult
ORDER BY total_profit DESC, full_name ASC
LIMIT 50;
