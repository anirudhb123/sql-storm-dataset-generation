
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependencies,
        STRING_AGG(DISTINCT cd_marital_status) AS marital_statuses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateRanges AS (
    SELECT 
        MIN(d_date) AS min_date,
        MAX(d_date) AS max_date
    FROM 
        date_dim
)
SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.street_details,
    c.cd_gender,
    c.total_customers,
    c.total_dependencies,
    c.marital_statuses,
    d.min_date,
    d.max_date
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > c.total_customers
CROSS JOIN 
    DateRanges d
ORDER BY 
    a.address_count DESC, 
    c.total_customers DESC;
