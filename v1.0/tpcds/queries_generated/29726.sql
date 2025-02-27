
WITH AddressInfo AS (
    SELECT 
        ca.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            ELSE 'Ms. ' || c.c_first_name
        END AS salutation,
        LEFT(c.c_email_address, 20) AS short_email,
        LENGTH(ca.ca_street_name) AS street_name_length,
        LENGTH(ca.ca_street_type) AS street_type_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
AggregateInfo AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(street_type_length) AS avg_street_type_length
    FROM 
        AddressInfo
    GROUP BY 
        ca_state
)
SELECT 
    ai.ca_state,
    ai.customer_count,
    ai.avg_street_name_length,
    ai.avg_street_type_length,
    CASE 
        WHEN ai.customer_count > 100 THEN 'High Activity'
        WHEN ai.customer_count > 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    AggregateInfo ai
ORDER BY 
    ai.customer_count DESC, 
    ai.ca_state;
