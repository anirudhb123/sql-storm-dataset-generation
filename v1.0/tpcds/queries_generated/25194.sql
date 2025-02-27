
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CA.ca_city,
        CA.ca_state,
        CA.ca_country,
        LEFT(c.c_email_address, 20) AS short_email,
        STRING_AGG(DISTINCT CONCAT(UPPER(CA.ca_street_number), ' ', CA.ca_street_name, ' ', CA.ca_street_type), '; ') AS address_summary
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, CA.ca_city, CA.ca_state, CA.ca_country, c.c_email_address
),
AddressCounts AS (
    SELECT 
        CA.ca_city,
        CA.ca_state,
        CA.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name) AS customer_names
    FROM 
        customer_address CA
    JOIN 
        customer c ON CA.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        CA.ca_city, CA.ca_state, CA.ca_country
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.short_email,
    ac.customer_count,
    ac.customer_names,
    LENGTH(cd.address_summary) AS address_length
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressCounts ac ON cd.ca_city = ac.ca_city AND cd.ca_state = ac.ca_state AND cd.ca_country = ac.ca_country
ORDER BY 
    LENGTH(cd.full_name) DESC, ac.customer_count DESC;
