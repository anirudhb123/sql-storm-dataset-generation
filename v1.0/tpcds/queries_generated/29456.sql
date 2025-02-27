
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(c.c_email_address, '@', ' [at] ') AS obfuscated_email,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_range AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
sales_info AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    dr.d_date,
    si.total_quantity,
    si.total_sales,
    ci.obfuscated_email,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
FROM 
    customer_info ci
JOIN 
    sales_info si ON ci.c_customer_id IN (
        SELECT c_customer_id 
        FROM web_sales 
        WHERE ws_sold_date_sk = si.ws_sold_date_sk
    )
JOIN 
    date_range dr ON dr.d_date_sk = si.ws_sold_date_sk
ORDER BY 
    dr.d_date DESC, 
    ci.full_name;
