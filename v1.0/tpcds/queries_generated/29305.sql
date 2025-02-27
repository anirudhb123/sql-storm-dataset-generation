
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
ConcatenatedAddress AS (
    SELECT 
        CONCAT_WS(', ', ca_street_name, ca_city, ca_state) AS full_address,
        address_rank
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 10
),
CustomerNames AS (
    SELECT 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_gender = 'F' 
        AND cd_marital_status = 'M' 
        AND cd_education_status LIKE '%college%'
)
SELECT 
    a.full_address,
    COUNT(*) AS customer_count,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name) AS customer_names
FROM 
    ConcatenatedAddress AS a
JOIN 
    customer AS c ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    CustomerNames AS cn ON cn.c_first_name = c.c_first_name AND cn.c_last_name = c.c_last_name
GROUP BY 
    a.full_address
ORDER BY 
    customer_count DESC;
