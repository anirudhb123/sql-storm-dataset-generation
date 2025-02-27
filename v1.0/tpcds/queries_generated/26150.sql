
WITH address_info AS (
    SELECT
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM
        customer_address
),
demographic_info AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_combination
    FROM
        customer_demographics
),
sales_info AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
ranked_sales AS (
    SELECT
        ws_bill_customer_sk,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_info
)
SELECT
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    s.total_sales,
    r.sales_rank
FROM
    address_info a
JOIN
    customer c ON a.full_address LIKE CONCAT('%', c.c_first_name, '%') OR a.full_address LIKE CONCAT('%', c.c_last_name, '%')
JOIN
    demographic_info d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN
    ranked_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN
    (SELECT DISTINCT gender_marital_combination FROM demographic_info) r ON r.gender_marital_combination = d.gender_marital_combination
WHERE
    a.ca_state = 'CA'
ORDER BY
    s.total_sales DESC,
    a.ca_city;
