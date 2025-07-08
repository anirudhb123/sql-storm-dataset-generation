
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_city
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ad.address_count,
        ad.street_details
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        AddressCounts ad ON ca.ca_city = ad.ca_city
)

SELECT 
    CONCAT('Customer Name: ', full_name, 
           ', Gender: ', cd_gender, 
           ', Marital Status: ', cd_marital_status, 
           ', Education: ', cd_education_status,
           ', Purchase Estimate: ', cd_purchase_estimate,
           ', City: ', ca_city, 
           ', State: ', ca_state, 
           ', Address Count: ', address_count, 
           ', Street Details: ', street_details) AS customer_info
FROM 
    CustomerDetails
WHERE 
    cd_purchase_estimate > 50000
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 10;
