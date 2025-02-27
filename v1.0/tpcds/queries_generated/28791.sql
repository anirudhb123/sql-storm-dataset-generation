
WITH AddressParts AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCustomer AS (
    SELECT 
        ac.ca_address_sk,
        cd.customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        ac.ca_country
    FROM 
        AddressParts ac
    JOIN 
        CustomerDetails cd ON cd.c_customer_sk IN (
            SELECT c_current_addr_sk 
            FROM customer 
            WHERE c_current_addr_sk IS NOT NULL
        )
),
AggregatedData AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS total_addresses,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        AddressCustomer ca
    JOIN 
        CustomerDetails cd ON ca.customer_name = cd.customer_name
    GROUP BY 
        ca.ca_state
)
SELECT 
    *, 
    ROUND((total_customers::decimal / NULLIF(total_addresses, 0)) * 100, 2) AS customer_address_ratio
FROM 
    AggregatedData
ORDER BY 
    ca_state;
