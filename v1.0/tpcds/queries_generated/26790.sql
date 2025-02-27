
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        TRIM(ca_city) AS city, 
        TRIM(ca_state) AS state
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM customer_demographics
),
JoinDemo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.full_address, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM customer c
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCount AS (
    SELECT 
        full_address, 
        COUNT(*) AS customer_count
    FROM JoinDemo
    GROUP BY full_address
),
AddressDetails AS (
    SELECT 
        j.full_address, 
        j.city, 
        j.state, 
        a.customer_count
    FROM JoinDemo j
    JOIN AddressCount a ON j.full_address = a.full_address
)
SELECT 
    ad.full_address, 
    ad.city, 
    ad.state, 
    ad.customer_count,
    LEFT(ad.city, 2) AS city_prefix,
    UPPER(ad.state) AS state_uppercase
FROM AddressDetails ad
WHERE ad.customer_count > 1
ORDER BY ad.customer_count DESC, ad.city ASC;
