
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location_info
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        addr.full_address,
        addr.location_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts addr ON c.c_current_addr_sk = addr.ca_address_sk
),
DateMetrics AS (
    SELECT 
        d.d_date_sk,
        d.d_month_seq,
        d.d_year,
        COUNT(*) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_sk, d.d_month_seq, d.d_year
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    ci.location_info,
    dm.d_month_seq,
    dm.d_year,
    dm.total_sales
FROM 
    CustomerInfo ci
JOIN 
    DateMetrics dm ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk = dm.d_date_sk LIMIT 1)
WHERE 
    ci.cd_gender = 'F' AND dm.total_sales > 5
ORDER BY 
    dm.d_year DESC, dm.d_month_seq DESC;
