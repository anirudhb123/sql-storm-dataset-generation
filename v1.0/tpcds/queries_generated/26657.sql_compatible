
WITH AddressDetails AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) ORDER BY ca_city) AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoDetails AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    WHERE 
        cd_income_band_sk IS NOT NULL 
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year, 
        COUNT(*) AS total_days
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.full_address_list, 
    d.cd_gender, 
    d.demographic_count, 
    dt.d_year, 
    dt.total_days
FROM 
    AddressDetails a
JOIN 
    DemoDetails d ON a.address_count > 50
CROSS JOIN 
    DateInfo dt
WHERE 
    dt.total_days > 0
ORDER BY 
    a.ca_state, d.cd_gender, dt.d_year;
