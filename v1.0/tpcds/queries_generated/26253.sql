
WITH Address_Analysis AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_country) AS country_upper,
        LENGTH(ca_zip) AS zip_length
    FROM
        customer_address
), Demographics_Analysis AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        TRIM(cd_credit_rating) AS credit_rating_cleaned,
        CONCAT('Income Band from ', ib_lower_bound, ' to ', ib_upper_bound) AS income_band_range
    FROM
        customer_demographics
    JOIN income_band ON cd_demo_sk = ib_income_band_sk
), Item_Analysis AS (
    SELECT
        i_item_sk,
        TRIM(i_item_desc) AS cleaned_description,
        REPLACE(i_product_name, ' ', '_') AS product_name_snake_case,
        CASE
            WHEN i_size IS NOT NULL THEN CONCAT('Size: ', i_size)
            ELSE 'Size: Not specified'
        END AS size_info
    FROM
        item
)
SELECT
    aa.full_address,
    da.city_lower,
    da.country_upper,
    da.credit_rating_cleaned,
    ia.cleaned_description,
    ia.product_name_snake_case,
    ia.size_info
FROM
    Address_Analysis aa
JOIN
    Demographics_Analysis da ON da.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_addr_sk = aa.ca_address_sk LIMIT 1)
JOIN
    Item_Analysis ia ON ia.i_item_sk = (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = aa.ca_address_sk LIMIT 1) LIMIT 1)
WHERE
    aa.zip_length BETWEEN 5 AND 10
ORDER BY
    aa.city_lower, da.credit_rating_cleaned;
