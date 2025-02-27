
WITH RenownedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(c.c_email_address) AS email_length,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status LIKE '%Bachelor%'
),
CityMetrics AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS num_customers,
        AVG(email_length) AS avg_email_length,
        SUM(total_purchases) AS total_purchases
    FROM 
        RenownedCustomers rc
    JOIN 
        customer_address ca ON rc.c_customer_id = ca.ca_address_id
    GROUP BY 
        ca.ca_city
),
FinalMetrics AS (
    SELECT 
        city,
        num_customers,
        avg_email_length,
        total_purchases,
        RANK() OVER (ORDER BY total_purchases DESC) AS city_rank
    FROM 
        CityMetrics
)
SELECT 
    city,
    num_customers,
    avg_email_length,
    total_purchases,
    city_rank
FROM 
    FinalMetrics
WHERE 
    city_rank <= 5
ORDER BY 
    city_rank;
