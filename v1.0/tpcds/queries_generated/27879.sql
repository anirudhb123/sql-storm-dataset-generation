
WITH StringData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(SUBSTRING(c.c_email_address, 1, 20)) AS short_email,
        INITCAP(c.ca_country) AS formatted_country,
        REPLACE(LOWER(ca_street_name), ' ', '-') AS hyphenated_street_name
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL 
),
AggregatedData AS (
    SELECT 
        SUBSTRING(full_name FROM 1 FOR 10) AS name_fragment,
        COUNT(*) AS occurrence
    FROM 
        StringData
    GROUP BY 
        name_fragment
)
SELECT 
    name_fragment,
    occurrence,
    STRING_AGG(CONCAT(short_email, ' (', formatted_country, ')')) AS emails_and_countries,
    COUNT(*) FILTER (WHERE occurrence > 1) AS duplicate_count
FROM 
    AggregatedData
GROUP BY 
    name_fragment
ORDER BY 
    occurrence DESC
LIMIT 100;
