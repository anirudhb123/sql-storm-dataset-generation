WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', 
               TRIM(ca_street_name), ' ', 
               TRIM(ca_street_type), ' ', 
               COALESCE(NULLIF(TRIM(ca_suite_number), ''), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
address_count AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM processed_addresses
    GROUP BY ca_state
),
concatenated_addresses AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY a.full_address) AS address_rank
    FROM processed_addresses a
    JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
)
SELECT 
    a.ca_state,
    STRING_AGG(CONCAT(a.full_address, ' ', a.ca_city, ', ', a.ca_state, ' ', a.ca_zip), '; ' ORDER BY a.address_rank) AS all_addresses,
    c.address_count
FROM concatenated_addresses a
JOIN address_count c ON a.ca_state = c.ca_state
GROUP BY a.ca_state, c.address_count
ORDER BY c.address_count DESC;