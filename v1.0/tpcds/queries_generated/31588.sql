
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, 1 AS depth
    FROM item
    WHERE i_color = 'Red'
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_brand, ih.depth + 1
    FROM item i
    INNER JOIN item_hierarchy ih ON i.item_sk = ih.i_item_sk 
    WHERE ih.depth < 5
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk > 2300
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    cs.ca_city,
    cs.ca_state,
    cs.cd_gender,
    ss.total_quantity,
    ss.total_profit
FROM item_hierarchy ih
JOIN sales_summary ss ON ih.i_item_sk = ss.ws_item_sk
JOIN customer_info cs ON ss.total_quantity > 10
WHERE ss.sales_rank = 1
AND (cs.ca_state IS NOT NULL OR cs.ca_city IS NOT NULL)
ORDER BY ss.total_profit DESC
LIMIT 50;
