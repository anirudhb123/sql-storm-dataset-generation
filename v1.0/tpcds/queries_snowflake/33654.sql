
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_size, 1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL AND i_size IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_size, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk 
    WHERE ih.level < 5
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500 
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS customer_total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),
final_summary AS (
    SELECT 
        ih.i_item_desc,
        CASE 
            WHEN ci.cd_gender = 'M' THEN 'Male'
            WHEN ci.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(ss.total_profit, 0.0) AS total_profit,
        COALESCE(ss.total_orders, 0) AS total_orders,
        ai.customer_count AS total_customers
    FROM item_hierarchy ih
    LEFT JOIN sales_summary ss ON ih.i_item_sk = ss.ws_item_sk
    LEFT JOIN customer_info ci ON ci.c_current_cdemo_sk = ih.i_item_sk
    LEFT JOIN address_info ai ON ai.ca_address_sk = ci.c_current_cdemo_sk
)
SELECT 
    f.i_item_desc,
    f.gender,
    f.total_profit,
    f.total_orders,
    f.total_customers,
    RANK() OVER (PARTITION BY f.gender ORDER BY f.total_profit DESC) AS rank_by_profit
FROM final_summary f
WHERE f.total_profit IS NOT NULL
ORDER BY f.total_profit DESC
FETCH FIRST 100 ROWS ONLY;
