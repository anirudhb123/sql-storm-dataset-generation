
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        AVG(DATEDIFF(d_date, '2000-01-01')) AS avg_days_since_2000,
        MAX(DATEDIFF(d_date, '2000-01-01')) AS max_days_since_2000,
        MIN(DATEDIFF(d_date, '2000-01-01')) AS min_days_since_2000
    FROM date_dim
    GROUP BY d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    d.d_year,
    d.total_dates,
    d.avg_days_since_2000,
    d.max_days_since_2000,
    d.min_days_since_2000
FROM AddressStats a
JOIN CustomerStats c ON a.total_addresses > 100
JOIN DateStats d ON d.total_dates > 5000
ORDER BY a.total_addresses DESC, c.total_customers DESC, d.total_dates DESC
LIMIT 10;
