
WITH customer_addresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
    WHERE ca_country = 'USA'
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_department,
        TRIM(UPPER(cd_education_status)) AS education_status,
        cd_purchase_estimate
    FROM customer_demographics
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographics_with_sales AS (
    SELECT 
        c.c_customer_sk,
        ca.full_address,
        cd.cd_gender,
        cd.education_status,
        cd.cd_purchase_estimate,
        ss.total_sales,
        ss.order_count
    FROM customer c
    JOIN customer_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    dws.full_address,
    dws.cd_gender,
    dws.education_status,
    dws.total_sales,
    dws.order_count,
    ROW_NUMBER() OVER (PARTITION BY dws.education_status ORDER BY dws.total_sales DESC) AS sales_rank
FROM demographics_with_sales dws
WHERE dws.order_count > 5
ORDER BY dws.total_sales DESC;
