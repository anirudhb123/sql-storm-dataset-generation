
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1 FOR CHAR_LENGTH(c.c_email_address)) AS email_domain
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_summary AS (
    SELECT 
        ci.full_name,
        COUNT(ws.ws_order_number) AS total_purchases,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name
),
age_groups AS (
    SELECT 
        CASE 
            WHEN EXTRACT(YEAR FROM AGE(TO_DATE(CONCAT(ci.c_birth_year, '-', ci.c_birth_month, '-', ci.c_birth_day)))::DATE) < 18 THEN 'Under 18'
            WHEN EXTRACT(YEAR FROM AGE(TO_DATE(CONCAT(ci.c_birth_year, '-', ci.c_birth_month, '-', ci.c_birth_day)))::DATE) BETWEEN 18 AND 25 THEN '18-25'
            WHEN EXTRACT(YEAR FROM AGE(TO_DATE(CONCAT(ci.c_birth_year, '-', ci.c_birth_month, '-', ci.c_birth_day)))::DATE) BETWEEN 26 AND 35 THEN '26-35'
            WHEN EXTRACT(YEAR FROM AGE(TO_DATE(CONCAT(ci.c_birth_year, '-', ci.c_birth_month, '-', ci.c_birth_day)))::DATE) BETWEEN 36 AND 50 THEN '36-50'
            ELSE '51 and above' 
        END AS age_group,
        SUM(ps.total_spent) AS total_spent_in_group
    FROM 
        purchase_summary ps
    JOIN 
        customer_info ci ON ps.full_name = ci.full_name
    GROUP BY 
        age_group
)
SELECT 
    age_group,
    total_spent_in_group,
    COUNT(*) AS customer_count
FROM 
    age_groups
GROUP BY 
    age_group
ORDER BY 
    total_spent_in_group DESC;
