
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM RankedCustomers
    WHERE rank <= 10
),
AddressCounts AS (
    SELECT 
        ca.city AS city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.city
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    ac.city,
    ac.customer_count,
    CONCAT('Customer ', tc.full_name, ' lives in ', ac.city, ' and has a purchase estimate of ', tc.cd_purchase_estimate) AS customer_summary
FROM TopCustomers tc
JOIN AddressCounts ac ON ac.customer_count > 50
ORDER BY tc.cd_purchase_estimate DESC, tc.full_name ASC;
