
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS addr_rank
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND cd_purchase_estimate > 1000
)
SELECT 
    a.ca_address_sk,
    a.ca_street_name,
    a.ca_city,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status
FROM 
    RankedAddresses a
JOIN 
    FilteredDemographics d ON d.cd_demo_sk IN (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_current_addr_sk = a.ca_address_sk
    )
WHERE 
    a.addr_rank <= 3 
ORDER BY 
    a.ca_city, 
    a.ca_street_name;
