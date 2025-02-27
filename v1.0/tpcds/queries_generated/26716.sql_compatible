
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(c.c_email_address, '@example.com', '@customer.com') AS modified_email,
        LENGTH(COALESCE(REPLACE(c.c_last_name, ' ', ''), '')) AS name_length,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_within_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Gender_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(name_length) AS avg_name_length,
        COUNT(CASE WHEN rank_within_gender <= 5 THEN 1 END) AS top_five_customers
    FROM 
        Ranked_Customers
    GROUP BY 
        cd_gender
)
SELECT 
    g.cd_gender,
    g.total_customers,
    g.avg_name_length,
    g.top_five_customers,
    a.ca_city,
    COUNT(*) AS address_count
FROM 
    Gender_Stats g
LEFT JOIN 
    customer_address a ON a.ca_address_id IN (
        SELECT 
            DISTINCT c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_current_cdemo_sk IN (
                SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = g.cd_gender
            )
    )
GROUP BY 
    g.cd_gender, a.ca_city
ORDER BY 
    g.cd_gender, address_count DESC;
