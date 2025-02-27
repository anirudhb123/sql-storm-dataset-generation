
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(ca_city, 'Unknown') AS city,
        COALESCE(ca_state, 'Unknown') AS state,
        COALESCE(cd_marital_status, 'U') AS marital_status,
        CONCAT(SUBSTRING(ca_street_name, 1, 30), '...', SUBSTRING(ca_zip, 1, 5)) AS address_info
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    AND cd_cd_demo_sk IS NOT NULL
),
AggregatedData AS (
    SELECT 
        gender,
        COUNT(*) AS customer_count,
        STRING_AGG(full_name, ', ') AS name_list,
        STRING_AGG(address_info, '; ') AS address_list,
        STRING_AGG(CONCAT(city, ', ', state), '; ') AS city_state_list
    FROM CustomerData
    GROUP BY gender
)
SELECT 
    gender,
    customer_count,
    name_list,
    address_list,
    city_state_list,
    LENGTH(name_list) AS total_name_length,
    CHAR_LENGTH(address_list) AS total_address_length
FROM AggregatedData
ORDER BY customer_count DESC;
