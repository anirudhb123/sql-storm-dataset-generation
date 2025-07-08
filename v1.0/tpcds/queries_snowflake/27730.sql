
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_number,
        ca.ca_street_type,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ca.ca_city IS NOT NULL
),
LocationSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count,
        LISTAGG(DISTINCT ca_zip, ', ') WITHIN GROUP (ORDER BY ca_zip) AS zip_codes,
        LISTAGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY ca_street_number, ca_street_name, ca_street_type) AS addresses
    FROM 
        CustomerDetails
    WHERE 
        rn = 1
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    ls.ca_city,
    ls.ca_state,
    ls.customer_count,
    ls.zip_codes,
    ls.addresses,
    CONCAT('There are ', ls.customer_count, ' married female customers living in ', ls.ca_city, ', ', ls.ca_state, '.') AS summary
FROM 
    LocationSummary ls
ORDER BY 
    ls.customer_count DESC;
