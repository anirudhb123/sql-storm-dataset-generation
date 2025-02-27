
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    ORDER BY cd.cd_purchase_estimate DESC
    LIMIT 10
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ca.full_address,
    ca.ca_city,
    ca.ca_state
FROM TopCustomers tc
JOIN CustomerAddresses ca ON tc.c_customer_id = ca.ca_address_sk
ORDER BY tc.cd_purchase_estimate DESC, ca.ca_city;
