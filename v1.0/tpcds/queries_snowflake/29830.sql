
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        LISTAGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
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
        COUNT(DISTINCT d_date) AS active_days,
        LISTAGG(d_day_name, ', ') AS days_of_week
    FROM 
        date_dim
    WHERE 
        d_current_year = 'Y'
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.total_addresses,
    a.street_names,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    d.d_year,
    d.active_days,
    d.days_of_week
FROM 
    address_summary a
JOIN 
    customer_summary c ON a.total_addresses > 0
JOIN 
    date_summary d ON d.active_days > 15
ORDER BY 
    a.ca_city, c.cd_gender;
