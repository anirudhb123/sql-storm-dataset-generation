
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', 1)) AS first_word,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', -1)) AS last_word,
        LENGTH(ca_street_name) AS total_length,
        LENGTH(TRIM(ca_street_name)) - LENGTH(REPLACE(TRIM(ca_street_name), ' ', '')) + 1 AS word_count
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS num_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics 
    GROUP BY cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        MAX(d_date) AS max_date,
        MIN(d_date) AS min_date,
        COUNT(*) AS total_days
    FROM date_dim 
    GROUP BY d_year
)
SELECT 
    a.first_word,
    a.last_word,
    a.total_length,
    a.word_count,
    d.cd_gender,
    d.num_customers,
    d.avg_dependent_count,
    d.total_purchase_estimate,
    year_info.d_year,
    year_info.max_date,
    year_info.min_date,
    year_info.total_days
FROM 
    AddressParts a
JOIN 
    Demographics d ON a.word_count BETWEEN 2 AND 5
CROSS JOIN 
    DateInfo year_info
WHERE 
    a.total_length > 20
ORDER BY 
    d.num_customers DESC, a.word_count ASC;
