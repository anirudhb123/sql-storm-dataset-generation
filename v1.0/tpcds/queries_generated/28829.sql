
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.md_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_month_seq,
        d.d_week_seq,
        d.d_year,
        d.d_day_name
    FROM 
        date_dim d
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
)
SELECT 
    ad.full_address,
    cd.customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    dd.d_date,
    dd.d_day_name
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN 
    DateDetails dd ON dd.d_date_sk IN (SELECT c_first_shipto_date_sk FROM customer WHERE c_customer_sk = cd.c_customer_sk)
WHERE 
    ad.ca_city LIKE 'New%' 
    AND cd.cd_purchase_estimate > 1000
ORDER BY 
    dd.d_date DESC, 
    cd.customer_name
LIMIT 100;
