
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
ProcessedData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ac.address_count,
        STRING_AGG(DISTINCT d.d_day_name, ', ') AS available_days
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        AddressCounts ac ON ca.ca_city = ac.ca_city
    LEFT JOIN 
        date_dim d ON DATE_PART('dow', CURRENT_DATE) = d.d_dow
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        ca.ca_city, 
        ac.address_count
)
SELECT 
    *,
    LENGTH(full_name) AS name_length,
    UPPER(full_name) AS upper_case_name
FROM 
    ProcessedData
WHERE 
    address_count > 1
ORDER BY 
    address_count DESC, 
    name_length ASC;
