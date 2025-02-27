
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics_Stats AS (
    SELECT 
        cd_gender,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Item_Stats AS (
    SELECT 
        i_brand,
        COUNT(*) AS total_items,
        STRING_AGG(i_item_desc, ', ') AS item_descriptions
    FROM 
        item
    GROUP BY 
        i_brand
)
SELECT 
    a.ca_city,
    a.address_count,
    a.street_details,
    d.cd_gender,
    d.total_purchase_estimate,
    d.avg_dep_count,
    i.i_brand,
    i.total_items,
    i.item_descriptions
FROM 
    Address_Stats a
JOIN 
    Demographics_Stats d ON a.address_count > 5
JOIN 
    Item_Stats i ON i.total_items > 10
ORDER BY 
    a.address_count DESC, 
    d.total_purchase_estimate DESC;
