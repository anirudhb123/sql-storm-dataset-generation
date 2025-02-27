
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length
    FROM
        customer_address
),
CustomerMetrics AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        AVG(cd.cd_dep_count) AS avg_dependencies,
        STRING_AGG(DISTINCT CONCAT(c.a_city, ', ', c.a_state), '; ') AS cities
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_day, c.c_birth_month, c.c_birth_year, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FinalBenchmark AS (
    SELECT
        cm.full_name,
        cm.c_birth_day,
        cm.c_birth_month,
        cm.c_birth_year,
        cm.cd_gender,
        cm.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        cm.address_count,
        cm.avg_dependencies,
        COUNT(DISTINCT wp.wp_web_page_id) AS total_web_pages,
        SUM(CASE WHEN wp.wp_char_count IS NOT NULL THEN wp.wp_char_count ELSE 0 END) AS total_char_count
    FROM
        CustomerMetrics cm
    JOIN
        AddressDetails ad ON cm.c_customer_sk = ad.ca_address_sk
    LEFT JOIN
        web_page wp ON cm.c_customer_sk = wp.wp_customer_sk
    GROUP BY
        cm.full_name, cm.c_birth_day, cm.c_birth_month, cm.c_birth_year, cm.cd_gender, cm.cd_marital_status, ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, ad.ca_country, cm.address_count, cm.avg_dependencies
)
SELECT
    *,
    CONCAT('Customer: ', full_name, '; Address: ', full_address, '; Total Address Count: ', address_count, '; Total Web Pages: ', total_web_pages, '; Total Character Count: ', total_char_count) AS benchmark_summary
FROM
    FinalBenchmark;
