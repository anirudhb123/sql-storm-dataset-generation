
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_address_count,
        COUNT(DISTINCT ca_city) AS unique_city_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        COUNT(CASE WHEN d_holiday = 'Y' THEN 1 END) AS total_holidays,
        COUNT(CASE WHEN d_weekend = 'Y' THEN 1 END) AS total_weekends
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    AS.state AS address_state,
    AS.unique_address_count,
    AS.unique_city_count,
    CD.cd_gender,
    CD.total_dependents,
    CD.avg_purchase_estimate,
    DS.total_days,
    DS.total_holidays,
    DS.total_weekends
FROM 
    AddressSummary AS
JOIN 
    CustomerDemographics CD ON 1 = 1
JOIN 
    DateSummary DS ON 1 = 1
ORDER BY 
    AS.state, CD.cd_gender;
