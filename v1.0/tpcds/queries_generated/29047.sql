
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr.'
            WHEN cd.cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_data AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_order_number
)
SELECT 
    cd.full_name,
    cd.email_length,
    cd.email_domain,
    cd.salutation,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    sd.total_sales,
    sd.order_count,
    sd.avg_sales_price
FROM customer_data cd
JOIN address_data ad ON cd.c_customer_id = ad.ca_address_id  -- pretending ca_address_id is related here for example
LEFT JOIN sales_data sd ON cd.c_customer_id = sd.ws_order_number   -- assuming order number is related to customer_id for example
WHERE cd.email_length > 10
ORDER BY cd.full_name;
