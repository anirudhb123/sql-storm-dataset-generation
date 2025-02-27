
WITH enriched_customer AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        a.ca_city,
        a.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 1 AND 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
            WHEN cd.cd_purchase_estimate > 5000 THEN 'High'
        END AS purchase_estimate_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_ship_mode_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN enriched_customer ec ON ws.ws_bill_customer_sk = ec.c_customer_id
    GROUP BY ws.ws_ship_mode_sk
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_product_name, 
        i.i_current_price,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_product_name, i.i_current_price
)
SELECT 
    ec.full_name,
    ec.ca_city,
    ec.ca_state,
    ss.total_orders,
    ss.total_sales,
    id.total_sold,
    id.total_profit,
    CONCAT('Purchase Band: ', ec.purchase_estimate_band) AS purchase_band,
    CONCAT('Gender: ', ec.cd_gender, ' | Marital Status: ', ec.cd_marital_status, ' | Education: ', ec.cd_education_status) AS demographics_info
FROM enriched_customer ec
JOIN sales_summary ss ON ec.c_customer_id IS NOT NULL
JOIN item_details id ON ec.c_customer_id IS NOT NULL
WHERE id.total_profit > 0
ORDER BY total_sales DESC, total_profit DESC
LIMIT 100;
