
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        CONCAT_WS(', ', 
            NULLIF(ca_street_number, ''), 
            NULLIF(ca_street_name, ''), 
            NULLIF(ca_city, ''), 
            NULLIF(ca_state, ''), 
            NULLIF(ca_zip, ''), 
            NULLIF(ca_country, '')
        ) AS full_address
    FROM customer_address
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS demographic_info
    FROM customer_demographics
),
date_info AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year,
        CONCAT(d_day_name, ', ', d_month_seq, '-', d_year) AS date_summary
    FROM date_dim
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        LTRIM(RTRIM(i_item_desc)) AS trimmed_item_desc,
        SUBSTRING(i_brand, 1, 10) AS short_brand_name
    FROM item
)

SELECT 
    a.full_address,
    d.demographic_info,
    da.date_summary,
    i.trimmed_item_desc,
    i.short_brand_name,
    AVG(i.i_current_price) AS avg_price
FROM address_parts a
JOIN demographics d ON d.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk LIMIT 1)
JOIN date_info da ON da.d_date_sk = (SELECT c_first_sales_date_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk LIMIT 1)
JOIN item_details i ON i.i_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk LIMIT 1) LIMIT 1)
GROUP BY 
    a.full_address,
    d.demographic_info,
    da.date_summary,
    i.trimmed_item_desc,
    i.short_brand_name
ORDER BY avg_price DESC
LIMIT 100;
