
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_order_number) AS rn
    FROM web_sales
    GROUP BY ws_order_number
),
promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        ca.ca_country,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, ca.ca_country, cd.cd_gender
),
item_details AS (
    SELECT 
        i.i_item_id,
        SUM(cs.cs_quantity) AS total_sold,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM item i
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_id
)

SELECT 
    ci.c_customer_id,
    ci.ca_country,
    ci.cd_gender,
    SUM(si.total_quantity) AS total_quantity,
    SUM(si.total_revenue) AS total_revenue,
    p.p_promo_name,
    p.order_count,
    p.total_profit,
    id.total_sold,
    id.avg_sales_price
FROM customer_info ci
LEFT JOIN sales_cte si ON ci.total_orders > 0 AND si.rn = 1
LEFT JOIN promotions p ON si.ws_order_number IS NOT NULL
LEFT JOIN item_details id ON id.total_sold > 100
WHERE ci.cd_gender IS NOT NULL
GROUP BY ci.c_customer_id, ci.ca_country, ci.cd_gender, p.p_promo_name, p.order_count, p.total_profit, id.total_sold, id.avg_sales_price
ORDER BY total_revenue DESC, total_quantity DESC
LIMIT 100;
