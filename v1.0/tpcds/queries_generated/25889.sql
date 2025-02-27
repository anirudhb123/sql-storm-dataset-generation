
WITH customer_info AS (
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
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk) AS sales_count
    FROM item i
), 
sales_summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ci.full_name, ci.ca_city
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ii.i_item_id,
    ii.i_item_desc,
    ii.i_brand,
    ii.i_category,
    ii.i_current_price,
    ss.total_quantity_sold,
    ss.total_revenue,
    ss.total_orders
FROM item_details ii
LEFT JOIN sales_summary ss ON ii.sales_count > 0
JOIN customer_info ci ON ci.c_customer_id = ss.full_name
WHERE 
    ii.i_current_price > 20.00
ORDER BY 
    ss.total_revenue DESC, 
    ss.total_orders DESC;
