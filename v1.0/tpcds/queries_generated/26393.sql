
WITH Address_Data AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
Date_Info AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        date_dim
    WHERE 
        d_year = 2023
), 
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    di.d_day_name,
    COUNT(*) AS transaction_count
FROM 
    Customer_Info ci
JOIN 
    Address_Data ad ON ci.c_customer_sk = ad.ca_address_sk
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    Date_Info di ON ws.ws_sold_date_sk = di.d_date_sk
GROUP BY 
    ci.customer_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ad.full_address, 
    ad.ca_city, 
    ad.ca_state, 
    ad.ca_zip, 
    di.d_day_name
ORDER BY 
    transaction_count DESC
LIMIT 100;
