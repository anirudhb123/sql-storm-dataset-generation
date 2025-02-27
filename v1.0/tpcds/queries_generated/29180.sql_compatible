
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_current_price
    FROM item i
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_week_seq,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
),
combined_data AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ii.i_product_name,
        ii.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        di.d_date
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    JOIN item_info ii ON sd.ws_item_sk = ii.i_item_sk
    JOIN date_info di ON sd.ws_sold_date_sk = di.d_date_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    i_product_name,
    i_item_desc,
    total_quantity,
    total_sales,
    d_date
FROM combined_data
WHERE (cd_gender = 'F' AND cd_marital_status = 'M') 
   OR (cd_gender = 'M' AND cd_marital_status = 'S')
ORDER BY total_sales DESC
LIMIT 100;
