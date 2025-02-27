
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS registration_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
sales_details AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        it.i_item_id,
        it.i_item_desc,
        it.i_brand,
        it.i_category,
        is.total_quantity_sold,
        is.total_sales,
        is.avg_sales_price
    FROM customer_info ci
    JOIN item i ON ci.c_customer_sk = i.i_item_sk
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    sd.full_name,
    sd.ca_city,
    sd.ca_state,
    sd.ca_country,
    sd.i_item_id,
    sd.i_item_desc,
    sd.i_brand,
    sd.i_category,
    sd.total_quantity_sold,
    FORMAT(sd.total_sales, 'C', 'en-US') AS formatted_sales,
    ROUND(sd.avg_sales_price, 2) AS rounded_avg_price
FROM sales_details sd
WHERE sd.total_quantity_sold > 100
ORDER BY sd.total_sales DESC
LIMIT 100;
