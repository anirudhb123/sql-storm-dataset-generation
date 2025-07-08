
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        da.full_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN RankedAddresses da ON c.c_current_addr_sk = da.ca_address_sk
)
SELECT 
    city_address.full_address,
    COUNT(*) AS customer_count,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    CustomerDetails city_address
JOIN customer_demographics demographic ON city_address.c_customer_sk = demographic.cd_demo_sk
WHERE 
    demographic.cd_gender = 'F'
GROUP BY 
    city_address.full_address, city_address.c_customer_sk, city_address.c_first_name, city_address.c_last_name, demographic.cd_gender, demographic.cd_marital_status
HAVING 
    COUNT(*) > 5
ORDER BY 
    customer_count DESC;
