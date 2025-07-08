
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_dep_count > 0
), Address_Aggregation AS (
    SELECT 
        full_address,
        COUNT(*) AS customer_count,
        LISTAGG(full_name, ', ') WITHIN GROUP (ORDER BY full_name) AS customer_names
    FROM 
        Ranked_Customers
    WHERE 
        rn <= 5
    GROUP BY 
        full_address
)
SELECT 
    aa.full_address,
    aa.customer_count,
    aa.customer_names,
    COUNT(DISTINCT ca.ca_city) AS distinct_cities
FROM 
    Address_Aggregation aa
JOIN 
    customer_address ca ON aa.full_address = CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip)
GROUP BY 
    aa.full_address, aa.customer_count, aa.customer_names
ORDER BY 
    aa.customer_count DESC;
