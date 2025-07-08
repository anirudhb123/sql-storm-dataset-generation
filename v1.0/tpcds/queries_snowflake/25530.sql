
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', c.c_last_name) 
            ELSE CONCAT('Ms. ', c.c_last_name) 
        END AS salutation,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS name_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ra.full_name,
        ra.salutation
    FROM 
        customer_address ca
    JOIN 
        RankedCustomers ra ON ca.ca_address_sk = ra.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(*) FILTER (WHERE ra.cd_gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE ra.cd_gender = 'F') AS female_count,
    LISTAGG(ra.full_name, ', ') AS customer_names
FROM 
    CustomerAddresses ca
JOIN 
    RankedCustomers ra ON ca.full_name = ra.full_name
GROUP BY 
    ca.ca_city,
    ca.ca_state
ORDER BY 
    ca.ca_city, 
    ca.ca_state;
