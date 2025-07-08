
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS row_num
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S'
        AND ca.ca_state IN ('NY', 'CA')
),
FilteredCustomers AS (
    SELECT 
        full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        ca_city, 
        ca_state, 
        ca_zip
    FROM 
        CustomerDetails
    WHERE 
        row_num <= 5
)
SELECT 
    ca.ca_city,
    COUNT(*) AS total_customers,
    LISTAGG(full_name, ', ') WITHIN GROUP (ORDER BY full_name) AS customer_names
FROM 
    FilteredCustomers AS fc
JOIN 
    customer_address AS ca ON fc.ca_city = ca.ca_city
GROUP BY 
    ca.ca_city
ORDER BY 
    total_customers DESC;
