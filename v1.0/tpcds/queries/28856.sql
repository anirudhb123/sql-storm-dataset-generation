
WITH StringAggregation AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS full_address,
        STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS reasons,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip
)
SELECT 
    full_name,
    full_address,
    total_returns,
    LENGTH(full_name) AS name_length,
    LENGTH(full_address) AS address_length
FROM 
    StringAggregation
ORDER BY 
    total_returns DESC
LIMIT 10;
