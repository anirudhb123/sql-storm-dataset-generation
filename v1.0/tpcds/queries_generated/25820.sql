
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address FROM 1 FOR 10) AS email_prefix,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT
        d.d_date_id,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE
        d.d_year BETWEEN 2019 AND 2023 
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    di.d_day_name,
    di.d_month_seq,
    di.d_year,
    COUNT(*) AS num_records,
    AVG(cd.email_length) AS avg_email_length
FROM 
    CustomerDetails cd
CROSS JOIN 
    DateInfo di
GROUP BY 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    di.d_day_name,
    di.d_month_seq,
    di.d_year
ORDER BY 
    num_records DESC, 
    cd.full_name;
