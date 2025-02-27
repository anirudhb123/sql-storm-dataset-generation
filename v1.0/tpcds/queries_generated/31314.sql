
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, i_current_price, i_class_id, 0 AS level
    FROM item
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item) -- Starting points (items above average price)
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price, i.i_class_id, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_class_id = i.i_class_id
    WHERE ih.level < 3 -- Limit hierarchy depth to 3
),

sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        FIRST_VALUE(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS latest_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),

customer_overview AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state
)

SELECT 
    dh.state,
    dh.total_customers,
    dh.avg_purchase_estimate,
    ih.i_item_desc,
    ih.i_current_price,
    sd.total_quantity,
    sd.total_sales,
    sd.latest_net_profit
FROM customer_overview dh
LEFT JOIN item_hierarchy ih ON true -- Using outer join to show summary even if no items are found
LEFT JOIN sales_data sd ON ih.i_item_sk = sd.ws_item_sk
WHERE dh.total_customers > 100
ORDER BY dh.state, sd.total_sales DESC
LIMIT 10;

