
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) ORDER BY ca_street_name) AS all_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
GenderDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS unique_days,
        STRING_AGG(d_day_name, ', ' ORDER BY d_dow) AS days_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.all_addresses,
    g.cd_gender,
    g.total_customers,
    g.total_dependents,
    d.d_year,
    d.unique_days,
    d.days_of_week
FROM 
    AddressInfo a
JOIN 
    GenderDemographics g ON g.total_customers > 100
JOIN 
    DateInfo d ON d.unique_days > 30
ORDER BY 
    a.ca_state, a.ca_city, g.cd_gender;
