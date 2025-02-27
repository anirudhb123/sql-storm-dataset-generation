
WITH AddressDetails AS (
    SELECT
        ca.ca_address_id,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ', ', TRIM(ca.ca_city), ', ', TRIM(ca.state), ' ', TRIM(ca.ca_zip)) AS full_address,
        ca.ca_country,
        LENGTH(TRIM(ca.ca_street_name)) AS street_name_length,
        LENGTH(TRIM(ca.ca_city)) AS city_length,
        CHAR_LENGTH(TRIM(ca_ca_zip)) AS zip_length
    FROM
        customer_address ca
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_id
),
DateFiltering AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM
        date_dim d
    WHERE
        d.d_year = 2023 AND d.d_dow IN (1, 2, 3, 4, 5)
),
FinalResult AS (
    SELECT
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        df.d_date,
        df.d_day_name
    FROM
        CustomerDetails cd
    JOIN
        DateFiltering df ON cd.full_address LIKE '%New York%'
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd.full_address, '; ') AS unique_addresses,
    MIN(df.d_date) AS first_interaction_date,
    MAX(df.d_date) AS last_interaction_date
FROM 
    FinalResult cd
JOIN 
    DateFiltering df ON cd.d_date = df.d_date;
