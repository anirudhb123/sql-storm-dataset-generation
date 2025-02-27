
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        DATE_FORMAT(CURRENT_DATE, '%Y-%m') AS current_month
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(sd.unique_pages, 0) AS unique_pages,
    cd.current_month
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE cd.cd_gender = 'F' 
AND cd.cd_marital_status = 'M' 
AND cd.cd_purchase_estimate > 1000
ORDER BY cd.full_name;
