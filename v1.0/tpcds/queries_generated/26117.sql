
WITH BaseData AS (
    SELECT 
        c.c_customer_id, 
        ca.ca_city, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_street_name || ' ' || ca.ca_street_number AS full_address,
        LENGTH(c.c_email_address) AS email_length,
        d.d_date AS purchase_date
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year = 2023
),
AggregatedData AS (
    SELECT 
        ca_city,
        COUNT(*) AS num_customers,
        AVG(email_length) AS avg_email_length,
        STRING_AGG(full_name, '; ') AS customer_names,
        STRING_AGG(full_address, '; ') AS addresses
    FROM 
        BaseData
    GROUP BY 
        ca_city
)
SELECT 
    ca_city, 
    num_customers, 
    avg_email_length, 
    customer_names, 
    addresses
FROM 
    AggregatedData
ORDER BY 
    num_customers DESC
LIMIT 10;
