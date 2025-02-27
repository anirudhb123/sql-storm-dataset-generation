
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name
    FROM 
        RankedAddresses
    WHERE 
        rank <= 3
),
AddressSummaries AS (
    SELECT 
        ca_state,
        STRING_AGG(ca_street_name, '; ') AS top_street_names,
        COUNT(*) AS street_count
    FROM 
        FilteredAddresses
    JOIN 
        customer_address ON customer_address.ca_address_sk = FilteredAddresses.ca_address_sk
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    top_street_names,
    street_count,
    CHAR_LENGTH(top_street_names) AS total_length_of_top_names,
    UPPER(top_street_names) AS upper_case_names
FROM 
    AddressSummaries
ORDER BY 
    ca_state;
