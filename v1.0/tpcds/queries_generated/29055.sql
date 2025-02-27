
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, '; ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        COUNT(*) AS date_count,
        STRING_AGG(DISTINCT d_day_name, ', ') AS days_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.cities,
    cd.cd_gender,
    cd.demographic_count,
    cd.max_purchase_estimate,
    cd.education_levels,
    di.d_year,
    di.date_count,
    di.days_of_week
FROM 
    AddressCounts ac
JOIN 
    CustomerDemographics cd ON ac.ca_state IS NOT NULL
JOIN 
    DateInfo di ON di.d_year IS NOT NULL
ORDER BY 
    ac.address_count DESC, cd.demographic_count DESC;
