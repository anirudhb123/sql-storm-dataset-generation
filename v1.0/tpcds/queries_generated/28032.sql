
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        c.customer_sk,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status
    FROM 
        RankedCustomers c
    WHERE 
        c.rank_by_purchase = 1
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ha.full_name,
    ha.cd_gender,
    ha.cd_marital_status,
    ha.cd_education_status,
    ca.ca_city,
    ca.ca_state,
    ca.customer_count
FROM 
    HighValueCustomers ha
JOIN 
    CustomerAddresses ca ON ha.customer_sk = ca.customer_sk
ORDER BY 
    ca.customer_count DESC, ha.full_name;
