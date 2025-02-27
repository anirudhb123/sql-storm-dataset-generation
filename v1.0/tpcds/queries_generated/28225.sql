
WITH AddressProcessed AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_country) AS country_upper,
        LENGTH(ca_zip) AS zip_length,
        REPLACE(ca_street_name, ' ', '-') AS street_name_hyphenated
    FROM 
        customer_address
),
DemoProcessed AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status_desc,
        UPPER(cd_education_status) AS education_uppercase,
        LPAD(cd_purchase_estimate, 10, '0') AS padded_purchase_estimate
    FROM 
        customer_demographics
),
DateProcessed AS (
    SELECT 
        d_date_sk,
        d_date,
        TO_CHAR(d_date, 'YYYY-MM-DD') AS formatted_date,
        EXTRACT(DOW FROM d_date) AS day_of_week,
        CASE 
            WHEN d_holiday = 'Y' THEN 'Holiday' 
            ELSE 'Regular Day' 
        END AS day_type
    FROM 
        date_dim
)
SELECT 
    ap.full_address,
    dp.marital_status_desc,
    dp.education_uppercase,
    dp.padded_purchase_estimate,
    dp.cd_gender,
    DatePart('year', dp_d.d_date) AS year,
    dp_d.day_of_week,
    dp_d.day_type
FROM
    AddressProcessed ap
JOIN
    customer c ON c.c_current_addr_sk = ap.ca_address_sk
JOIN
    DemoProcessed dp ON c.c_current_cdemo_sk = dp.cd_demo_sk
JOIN
    DateProcessed dp_d ON c.c_first_sales_date_sk = dp_d.d_date_sk
WHERE
    ap.city_lower LIKE '%city%'
    AND dp.purchase_estimate > 1000
ORDER BY 
    dp_d.d_date DESC, 
    ap.full_address;
