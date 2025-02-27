
WITH AddressData AS (
    SELECT
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
GenderDemographics AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
AgeDemographics AS (
    SELECT
        CASE
            WHEN c_birth_year > 1980 THEN '18-30'
            WHEN c_birth_year BETWEEN 1971 AND 1980 THEN '31-40'
            WHEN c_birth_year BETWEEN 1961 AND 1970 THEN '41-50'
            ELSE '51+'
        END AS age_group,
        COUNT(*) AS age_count
    FROM 
        customer
    GROUP BY 
        CASE
            WHEN c_birth_year > 1980 THEN '18-30'
            WHEN c_birth_year BETWEEN 1971 AND 1980 THEN '31-40'
            WHEN c_birth_year BETWEEN 1961 AND 1970 THEN '41-50'
            ELSE '51+'
        END
),
SalesAggregation AS (
    SELECT
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT
    a.ca_city,
    a.ca_state,
    a.full_address,
    a.address_count,
    g.cd_gender,
    g.gender_count,
    ag.age_group,
    ag.age_count,
    sa.total_sales
FROM
    AddressData a
LEFT JOIN 
    GenderDemographics g ON a.address_count > 0 -- Assuming association based on records
LEFT JOIN 
    AgeDemographics ag ON ag.age_count > 0 -- Assuming association based on records
LEFT JOIN 
    SalesAggregation sa ON a.address_count > 0 -- Assuming association based on records
ORDER BY 
    a.ca_city, a.ca_state, a.address_count DESC;
