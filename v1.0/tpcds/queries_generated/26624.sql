
WITH AddressDetails AS (
    SELECT 
        ca_state, 
        ca_city, 
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state, ca_city
), 
Demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
), 
Combined AS (
    SELECT 
        ad.ca_state, 
        ad.ca_city, 
        ad.customer_names, 
        dm.cd_gender, 
        dm.cd_marital_status, 
        dm.customer_count
    FROM 
        AddressDetails ad
    LEFT JOIN 
        Demographics dm ON ad.ca_state = 'CA' AND ad.ca_city = 'Los Angeles'
)
SELECT 
    ca_state, 
    ca_city, 
    customer_names, 
    cd_gender, 
    cd_marital_status, 
    customer_count
FROM 
    Combined
WHERE 
    customer_count > 10
ORDER BY 
    ca_state, ca_city;
