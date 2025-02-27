
WITH ProcessedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(CASE 
            WHEN cd.cd_buy_potential IS NULL THEN 'Unknown'
            ELSE cd.cd_buy_potential
        END, 'No Data') AS buying_potential,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTR(c.c_email_address, INSTR(c.c_email_address, '@') + 1) AS email_domain,
        UPPER(SUBSTR(c.c_first_name, 1, 1)) || LOWER(SUBSTR(c.c_first_name, 2)) AS formatted_first_name
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND ca.ca_state = 'CA'
),
CustomerEmailStats AS (
    SELECT 
        full_name,
        COUNT(*) AS total_emails,
        SUM(email_length) AS total_email_length,
        MAX(email_length) AS max_email_length,
        MIN(email_length) AS min_email_length,
        AVG(email_length) AS avg_email_length
    FROM 
        ProcessedCustomerData
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    total_emails,
    total_email_length,
    max_email_length,
    min_email_length,
    avg_email_length,
    CASE 
        WHEN avg_email_length > 20 THEN 'Long Emails'
        WHEN avg_email_length BETWEEN 10 AND 20 THEN 'Medium Emails'
        ELSE 'Short Emails' 
    END AS email_category
FROM 
    CustomerEmailStats
ORDER BY 
    avg_email_length DESC;
