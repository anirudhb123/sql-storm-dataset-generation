
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        COALESCE(NULLIF(UPPER(c.c_email_address), ''), 'NO_EMAIL') AS email_status,
        REPLACE(ca.city, ' ', '-') AS city_slug,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTR(d.d_date, 1, 7) AS purchase_month
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT 
    customer_full_name,
    email_status,
    city_slug,
    gender_description,
    email_length,
    COUNT(*) AS total_purchases
FROM 
    processed_data
GROUP BY 
    customer_full_name, email_status, city_slug, gender_description, email_length
HAVING 
    email_length > 0 
ORDER BY 
    total_purchases DESC
LIMIT 100;
