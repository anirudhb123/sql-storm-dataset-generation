
WITH RECURSIVE AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', 1)) AS street_part,
        1 AS part_level
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ap.ca_address_sk,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ca_street_name, ' ', part_level + 1), ' ', -1)) AS street_part,
        ap.part_level + 1
    FROM 
        AddressParts ap
    JOIN 
        customer_address ca ON ap.ca_address_sk = ca.ca_address_sk
    WHERE 
        part_level < CHAR_LENGTH(ca.ca_street_name) - CHAR_LENGTH(REPLACE(ca.ca_street_name, ' ', ''))
)
SELECT 
    a.ca_address_sk,
    GROUP_CONCAT(a.street_part ORDER BY a.part_level) AS reconstructed_street
FROM 
    AddressParts a
GROUP BY 
    a.ca_address_sk
HAVING 
    LENGTH(reconstructed_street) > 0
ORDER BY 
    a.ca_address_sk;
