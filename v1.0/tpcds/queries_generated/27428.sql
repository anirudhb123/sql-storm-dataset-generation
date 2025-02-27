
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ranked_sales AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        sd.total_sales,
        sd.order_count,
        DENSE_RANK() OVER (PARTITION BY ci.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    total_sales,
    order_count,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 10
ORDER BY cd_gender, sales_rank;
