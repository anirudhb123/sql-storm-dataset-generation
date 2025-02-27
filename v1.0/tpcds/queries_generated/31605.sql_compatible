
WITH RECURSIVE selected_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws) AND p.p_end_date_sk >= (SELECT MIN(ws.ws_sold_date_sk) FROM web_sales ws)
),
sales_summary AS (
    SELECT
        si.ws_item_sk,
        SUM(si.ws_quantity) AS total_quantity,
        AVG(si.ws_sales_price) AS avg_sales_price,
        SUM(si.ws_sales_price * si.ws_quantity) AS total_revenue
    FROM selected_sales si
    GROUP BY si.ws_item_sk
)
SELECT
    ci.c_first_name, 
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    id.i_item_desc,
    ss.total_quantity,
    ss.avg_sales_price,
    ss.total_revenue,
    RANK() OVER (PARTITION BY ci.ca_city ORDER BY ss.total_revenue DESC) AS revenue_rank
FROM sales_summary ss
JOIN item_details id ON ss.ws_item_sk = id.i_item_sk
JOIN customer_info ci ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ss.ws_item_sk LIMIT 1)
WHERE ss.total_quantity > 50 AND id.i_current_price IS NOT NULL
ORDER BY ci.ca_state, revenue_rank;
