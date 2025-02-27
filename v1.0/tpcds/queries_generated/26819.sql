
WITH address_preps AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_zip LIKE '_____' THEN 'Standard'
            WHEN ca_zip LIKE '__%_%' THEN 'Complex'
            ELSE 'Other'
        END AS zip_category
    FROM customer_address
),
demo_preps AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demo_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status, cd_education_status
),
combined AS (
    SELECT
        d.d_date,
        d.d_month_seq,
        a.full_address,
        a.ca_city,
        a.ca_state,
        dmo.cd_gender,
        dmo.cd_marital_status,
        dmo.cd_education_status,
        dmo.demo_count,
        a.zip_category
    FROM date_dim d
    JOIN address_preps a ON d.d_date_sk = a.full_address
    JOIN demo_preps dmo ON a.zip_category = CASE 
                                             WHEN dmo.cd_marital_status = 'M' THEN 'Standard'
                                             WHEN dmo.cd_marital_status = 'S' THEN 'Complex'
                                             ELSE 'Other'
                                           END
    WHERE d.d_year = 2023
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    SUM(demo_count) AS total_demos,
    COUNT(DISTINCT full_address) AS unique_addresses
FROM combined
GROUP BY 
    full_address,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status
ORDER BY 
    total_demos DESC, 
    unique_addresses ASC;
