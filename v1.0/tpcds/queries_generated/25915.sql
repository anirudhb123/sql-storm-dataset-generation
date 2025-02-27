
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date >= '2022-01-01' AND d_date <= '2022-12-31'
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
)
SELECT
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM customer_details cd
LEFT JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
WHERE cd.ca_state IN ('CA', 'NY', 'TX')
ORDER BY total_sales DESC
FETCH FIRST 100 ROWS ONLY;
