
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 
           i_current_price, i_wholesale_cost, 
           CAST(i_item_desc AS VARCHAR) AS full_desc, 
           1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_item_desc, 
           ih.i_current_price, ih.i_wholesale_cost, 
           CONCAT(ih.full_desc, ' -> ', i.i_item_desc),
           ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk 
    WHERE ih.level < 5 
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
),
customer_summary AS (
    SELECT 
        ca.ca_city AS city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS max_credit_rating,
        CASE 
            WHEN AVG(cd.cd_dep_count) > 2 THEN 'High Dependency'
            ELSE 'Low Dependency'
        END AS dependency_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
)
SELECT 
    s.city,
    s.customer_count,
    s.avg_purchase_estimate,
    s.max_credit_rating,
    s.dependency_category,
    ss.total_quantity,
    ss.total_profit,
    ss.order_count,
    ih.full_desc,
    ih.level
FROM customer_summary s
LEFT JOIN sales_summary ss ON s.city = ss.w_warehouse_id 
LEFT JOIN item_hierarchy ih ON ih.i_item_sk = (SELECT i_item_sk FROM item ORDER BY RANDOM() LIMIT 1) 
WHERE s.customer_count > 10
    AND COALESCE(ss.total_profit, 0) > 1000
ORDER BY s.city, ss.total_profit DESC;
