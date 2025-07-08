
WITH Address_City AS (
    SELECT 
        ca_city, 
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Customer_Gender AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count,
        LISTAGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.address_count,
    a.street_names,
    g.cd_gender,
    g.customer_count,
    g.customer_names
FROM 
    Address_City a
LEFT JOIN 
    Customer_Gender g ON (a.address_count > 50 AND g.customer_count > 100)
ORDER BY 
    a.address_count DESC, g.customer_count DESC;
