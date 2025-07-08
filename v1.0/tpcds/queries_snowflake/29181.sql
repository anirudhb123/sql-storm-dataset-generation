
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state
    FROM 
        RankedAddresses
    WHERE 
        rank <= 5
),
AddressConcatenation AS (
    SELECT 
        ca_state,
        LISTAGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS top_street_names,
        COUNT(ca_address_sk) AS address_count
    FROM 
        FilteredAddresses
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    top_street_names,
    address_count,
    REGEXP_REPLACE(top_street_names, '[^A-Za-z0-9, ]', '') AS clean_street_names
FROM 
    AddressConcatenation
ORDER BY 
    ca_state;
