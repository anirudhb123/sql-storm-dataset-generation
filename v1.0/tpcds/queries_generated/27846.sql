
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        c.c_email_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_current_price
    FROM item i
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN ws.web_site_id IS NOT NULL THEN 'Web'
            WHEN ss.s_store_sk IS NOT NULL THEN 'Store'
            ELSE 'Catalog'
        END AS sales_channel,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number::integer
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number::integer
    GROUP BY sales_channel
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    ii.i_product_name,
    ii.i_item_desc,
    ii.i_current_price,
    ss.sales_channel,
    ss.total_orders,
    ss.total_sales
FROM customer_info ci
JOIN item_info ii ON ci.c_customer_id = ii.i_item_id
JOIN sales_summary ss ON ss.total_orders > 0
WHERE ci.cd_gender = 'F' 
    AND (ci.ca_city LIKE '%York%' OR ci.ca_state = 'NY')
ORDER BY ss.total_sales DESC, ci.full_name
LIMIT 100;
