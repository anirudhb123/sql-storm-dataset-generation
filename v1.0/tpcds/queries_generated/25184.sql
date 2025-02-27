
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        STRING_AGG(d_day_name, ', ') AS days_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.address_list,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    c.customer_names,
    d.d_year,
    d.total_days,
    d.days_of_week
FROM 
    address_summary a
JOIN 
    customer_summary c ON c.total_customers > 0
JOIN 
    date_summary d ON d.total_days > 0
ORDER BY 
    a.total_addresses DESC, c.total_customers DESC;
