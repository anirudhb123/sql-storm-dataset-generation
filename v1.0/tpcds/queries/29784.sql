
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateDemographics AS (
    SELECT 
        ca_country,
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses,
        STRING_AGG(cd_education_status, ', ') AS education_statuses
    FROM 
        AddressDetails
    GROUP BY 
        ca_country, cd_gender
),
RankedDemographics AS (
    SELECT 
        ca_country,
        cd_gender,
        customer_count,
        avg_purchase_estimate,
        marital_statuses,
        education_statuses,
        ROW_NUMBER() OVER (PARTITION BY ca_country ORDER BY customer_count DESC) AS rank
    FROM 
        AggregateDemographics
)
SELECT 
    ca_country,
    cd_gender,
    customer_count,
    avg_purchase_estimate,
    marital_statuses,
    education_statuses
FROM 
    RankedDemographics
WHERE 
    rank <= 3
ORDER BY 
    ca_country, customer_count DESC;
