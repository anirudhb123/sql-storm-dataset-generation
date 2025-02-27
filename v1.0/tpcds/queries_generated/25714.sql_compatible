
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
DemographicsDetails AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        cd_demo_sk
    FROM 
        customer_demographics
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicsDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
TopCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS customer_count
    FROM 
        AddressDetails
    GROUP BY 
        ca_city
    ORDER BY 
        customer_count DESC
    LIMIT 5
),
CityCustomerDetails AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.full_address,
        cs.ca_city,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status
    FROM 
        CustomerSummary cs
    JOIN 
        TopCities tc ON cs.ca_city = tc.ca_city
)
SELECT 
    ca_city AS city,
    STRING_AGG(CONCAT(c_customer_id, ': ', c_first_name, ' ', c_last_name), ', ') AS customer_list,
    COUNT(c_customer_id) AS total_customers
FROM 
    CityCustomerDetails
GROUP BY 
    ca_city;
