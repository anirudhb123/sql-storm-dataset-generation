
WITH RankedCustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS address_rank
    FROM 
        customer_address
),
CustomerDemographicsWithState AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_state
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(full_address, ', ') AS address_list
    FROM 
        RankedCustomerAddresses
    GROUP BY 
        ca_state
)
SELECT 
    demo.cd_demo_sk,
    demo.cd_gender,
    demo.cd_marital_status,
    demo.cd_education_status,
    demo.cd_purchase_estimate,
    demo.cd_credit_rating,
    demo.cd_dep_count,
    demo.cd_dep_employed_count,
    demo.cd_dep_college_count,
    stats.address_count,
    stats.address_list
FROM 
    CustomerDemographicsWithState demo
JOIN 
    AddressStats stats ON demo.ca_state = stats.ca_state
WHERE 
    demo.cd_purchase_estimate > 1000
ORDER BY 
    demo.cd_demo_sk;
