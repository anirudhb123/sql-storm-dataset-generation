
WITH StringProcessing AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state) AS full_address,
        TRIM(REPLACE(UPPER(ca_street_name), ' ', '')) AS cleaned_street_name
    FROM 
        customer_address
),
AddressAggregates AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length,
        AVG(LENGTH(full_address)) AS avg_address_length,
        STRING_AGG(DISTINCT cleaned_street_name, ', ') AS unique_street_names
    FROM 
        StringProcessing
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.address_count,
    a.max_address_length,
    a.min_address_length,
    a.avg_address_length,
    a.unique_street_names,
    d.d_year,
    COUNT(ws.ws_order_number) AS total_sales_per_year
FROM 
    AddressAggregates a
JOIN 
    date_dim d ON EXTRACT(YEAR FROM d.d_date) = EXTRACT(YEAR FROM DATE '2002-10-01')
LEFT JOIN 
    web_sales ws ON ws.ws_ship_date_sk = d.d_date_sk
GROUP BY 
    a.ca_state, a.address_count, a.max_address_length, a.min_address_length, a.avg_address_length, a.unique_street_names, d.d_year
ORDER BY 
    a.address_count DESC, a.ca_state;
