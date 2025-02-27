
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        ARRAY_AGG(DISTINCT ca_city) AS unique_cities,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS all_street_info
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        STRING_AGG(DISTINCT d_day_name, ', ') AS day_names
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    AS.addr.ca_state,
    AS.total_addresses,
    ARRAY_LENGTH(AS.unique_cities, 1) AS city_count,
    AS.all_street_info,
    CD.cd_gender,
    CD.total_customers,
    CD.avg_purchase_estimate,
    CD.marital_statuses,
    DS.d_year,
    DS.total_dates,
    DS.day_names
FROM 
    AddressStats AS AS
JOIN 
    CustomerDemographics AS CD ON TRUE
JOIN 
    DateSummary AS DS ON TRUE
ORDER BY 
    AS.addr.ca_state, CD.cd_gender, DS.d_year;
