
WITH customer_details AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count
    FROM
        catalog_sales
    GROUP BY
        cs_bill_customer_sk
),
combined_summary AS (
    SELECT
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM
        customer_details AS cd
    LEFT JOIN sales_summary AS ss ON cd.c_customer_id = ss.cs_bill_customer_sk
)
SELECT
    *,
    CASE
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    CONCAT(cd_city, ', ', cd_state, ', ', cd_country) AS location_info
FROM
    combined_summary
ORDER BY
    total_sales DESC,
    full_name;
