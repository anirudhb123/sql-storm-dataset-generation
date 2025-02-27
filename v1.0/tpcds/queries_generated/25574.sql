
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM item i
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ci.full_name,
        ii.i_item_desc
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    JOIN item_info ii ON ws.ws_item_sk = ii.i_item_id
)
SELECT 
    full_name,
    i_item_desc,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price) AS total_sales,
    AVG(ws_sales_price) AS average_price
FROM sales_data
GROUP BY full_name, i_item_desc
HAVING total_quantity > 10
ORDER BY total_sales DESC
LIMIT 100;
