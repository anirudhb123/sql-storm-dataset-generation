
WITH CustomerCategories AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        LISTAGG(DISTINCT c.c_email_address, ', ') WITHIN GROUP (ORDER BY c.c_email_address) AS email_addresses,
        LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_names
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),

TopCities AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
    ORDER BY 
        customer_count DESC
    LIMIT 5
)

SELECT 
    cc.cd_gender,
    cc.customer_count,
    cc.email_addresses,
    cc.customer_names,
    tc.ca_city,
    tc.customer_count AS city_customer_count
FROM 
    CustomerCategories cc
JOIN 
    TopCities tc ON cc.customer_count > tc.customer_count
ORDER BY 
    cc.customer_count DESC, 
    tc.customer_count DESC;
