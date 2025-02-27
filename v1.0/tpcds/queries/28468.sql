
WITH AddressCount AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependencies,
        MIN(cd_dep_employed_count) AS min_employed_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
WarehousesWithHighFootTraffic AS (
    SELECT 
        s_city, 
        COUNT(DISTINCT w_warehouse_id) AS warehouse_count
    FROM 
        store
    JOIN 
        warehouse ON w_warehouse_id = s_store_id
    GROUP BY 
        s_city
    HAVING 
        COUNT(DISTINCT w_warehouse_id) > 5
)
SELECT 
    a.ca_city,
    a.city_address_count,
    a.street_names,
    d.cd_gender,
    d.avg_purchase_estimate,
    d.max_dependencies,
    d.min_employed_dependents,
    w.warehouse_count
FROM 
    AddressCount a
JOIN 
    DemographicStats d ON a.city_address_count > 10
JOIN 
    WarehousesWithHighFootTraffic w ON w.s_city = a.ca_city
WHERE 
    d.avg_purchase_estimate > 500
ORDER BY 
    a.city_address_count DESC, 
    d.avg_purchase_estimate DESC;
