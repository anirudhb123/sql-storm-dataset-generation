
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY ca_address_sk) AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), CustomerDemographics AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(CONCAT(cd_gender, ': ', cd_marital_status), '; ') WITHIN GROUP (ORDER BY cd_gender) AS gender_marital_status
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), DateSummary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        LISTAGG(d_day_name, ', ') WITHIN GROUP (ORDER BY d_date_sk) AS day_names
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.unique_addresses,
    a.full_address_list,
    c.cd_gender,
    c.total_dependents,
    c.avg_purchase_estimate,
    c.gender_marital_status,
    d.d_year,
    d.total_days,
    d.day_names
FROM 
    AddressDetails a
JOIN 
    CustomerDemographics c ON a.ca_state = 'CA'
JOIN 
    DateSummary d ON d.d_year = 2023
ORDER BY 
    a.ca_city, c.cd_gender;
