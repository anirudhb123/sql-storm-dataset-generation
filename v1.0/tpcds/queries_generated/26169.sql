
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
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
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
high_value_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_product_name,
        is.total_sales,
        is.total_orders
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    WHERE is.total_sales > 1000
),
demographic_sales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        hvi.i_item_desc,
        hvi.i_product_name,
        hvi.total_sales
    FROM customer_info ci
    JOIN store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    JOIN high_value_items hvi ON ss.ss_item_sk = hvi.i_item_sk
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    COUNT(ds.full_name) AS customer_count,
    SUM(ds.total_sales) AS total_sales_amount
FROM demographic_sales ds
GROUP BY 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status
ORDER BY total_sales_amount DESC;
