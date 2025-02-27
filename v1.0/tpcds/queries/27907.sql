
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_city, ', ' ORDER BY ca_city) AS city_list,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS unique_street_types,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS credit_rating_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ItemStats AS (
    SELECT 
        i_brand,
        COUNT(*) AS total_items,
        SUM(i_current_price) AS total_price,
        STRING_AGG(i_category, ', ') AS category_list
    FROM 
        item
    GROUP BY 
        i_brand
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.city_list,
    a.unique_street_types,
    a.avg_gmt_offset,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    c.credit_rating_list,
    i.i_brand,
    i.total_items,
    i.total_price,
    i.category_list
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.total_addresses > 50
JOIN 
    ItemStats i ON c.total_customers > 1000
ORDER BY 
    a.ca_state, c.cd_gender, i.i_brand;
