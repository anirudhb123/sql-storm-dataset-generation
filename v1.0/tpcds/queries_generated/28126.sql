
WITH address_stats AS (
    SELECT 
        ca_country,
        COUNT(*) AS address_count,
        STRING_AGG(CASE WHEN ca_state IS NOT NULL THEN ca_state END, ', ') AS states,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_country
),
customer_summary AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
warehouse_info AS (
    SELECT 
        w_country,
        COUNT(*) AS warehouse_count,
        STRING_AGG(w_city, ', ') AS cities_with_warehouses
    FROM 
        warehouse
    GROUP BY 
        w_country
)
SELECT 
    a.ca_country,
    a.address_count,
    a.states,
    a.unique_cities,
    c.cd_gender,
    c.avg_purchase_estimate,
    c.marital_statuses,
    c.customer_count,
    w.warehouse_count,
    w.cities_with_warehouses
FROM 
    address_stats a
JOIN 
    customer_summary c ON a.ca_country = 'USA' -- Filtering for a specific country
JOIN 
    warehouse_info w ON a.ca_country = w.w_country
WHERE 
    c.customer_count > 50 -- Filtering customer summary by customer count
ORDER BY 
    a.address_count DESC, 
    c.avg_purchase_estimate DESC;
