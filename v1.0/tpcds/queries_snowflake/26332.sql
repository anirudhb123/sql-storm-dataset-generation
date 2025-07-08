
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip,
        LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS unique_street_types,
        LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS unique_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
)
SELECT 
    a.ca_city,
    a.address_count,
    a.max_zip,
    a.min_zip,
    a.unique_street_types,
    a.unique_street_names,
    COALESCE(cc.customer_count, 0) AS customer_count
FROM 
    AddressStats AS a
LEFT JOIN 
    CustomerCounts AS cc ON a.ca_city = cc.ca_city
ORDER BY 
    a.address_count DESC;
