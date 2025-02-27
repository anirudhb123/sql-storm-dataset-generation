
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), ''), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemoConcat AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status, 
               ' Est. Purchase: ', cd_purchase_estimate, 
               ' Credit Rating: ', cd_credit_rating) AS demographic_info
    FROM 
        customer_demographics
),
DateDetails AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'YYYY-MM-DD') AS formatted_date,
        d_day_name
    FROM 
        date_dim
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name, ' (', c.c_email_address, ')') AS customer_name,
        ac.full_address,
        dc.demographic_info,
        dd.formatted_date,
        dd.d_day_name
    FROM 
        customer c
    JOIN 
        AddressConcat ac ON c.c_current_addr_sk = ac.ca_address_sk
    JOIN 
        DemoConcat dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
    JOIN 
        DateDetails dd ON c.c_first_shipto_date_sk = dd.d_date_sk
)
SELECT 
    customer_name,
    full_address,
    demographic_info,
    formatted_date,
    d_day_name
FROM 
    CustomerDetails
WHERE 
    d_day_name IN ('Monday', 'Friday')
ORDER BY 
    customer_name;
