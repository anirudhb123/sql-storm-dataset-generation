
WITH ProcessedCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CA.ca_city AS city,
        CA.ca_state AS state,
        CD.cd_gender,
        CONCAT(TRIM(CD.cd_marital_status), ' ', SUBSTR(CD.cd_education_status, 1, 3)) AS marital_edu_status,
        (REPLACE(CD.cd_credit_rating, ' ', '') || ' | ' || CAST(DATE_FORMAT(NOW(), '%Y-%m-%d') AS CHAR)) AS credit_info
    FROM 
        customer c
    JOIN 
        customer_demographics CD ON CD.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address CA ON CA.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    full_name,
    city,
    state,
    cd_gender,
    LENGTH(marital_edu_status) AS marital_edu_length,
    LOCATE(' ', credit_info) AS space_position,
    REVERSE(full_name) AS reversed_name
FROM 
    ProcessedCustomerInfo
WHERE 
    cd_gender = 'M'
ORDER BY 
    LENGTH(full_name) DESC, 
    city ASC, 
    state ASC;
