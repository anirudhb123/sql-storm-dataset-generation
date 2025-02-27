
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_street_name, a.ca_city, a.ca_state, ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE ah.level < 5
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country IS NOT NULL
    GROUP BY ws.ws_item_sk
),
high_profit_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.avg_profit,
        RANK() OVER (ORDER BY sd.avg_profit DESC) AS profit_rank
    FROM sales_data sd
    WHERE sd.avg_profit > (SELECT AVG(avg_profit) FROM sales_data)
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(hp.total_quantity, 0) AS total_quantity,
        COALESCE(hp.avg_profit, 0) AS avg_profit
    FROM item i
    LEFT JOIN high_profit_sales hp ON i.i_item_sk = hp.ws_item_sk
)
SELECT 
    CONCAT('Item: ', id.i_item_desc, ' | Quantity Sold: ', id.total_quantity) AS item_sales_info,
    CASE 
        WHEN id.avg_profit > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status,
    ah.ca_city,
    ah.ca_state,
    ah.level
FROM item_details id
JOIN address_hierarchy ah ON ah.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL LIMIT 1)
WHERE id.total_quantity > 0
GROUP BY id.i_item_desc, id.total_quantity, id.avg_profit, ah.ca_city, ah.ca_state, ah.level
ORDER BY id.avg_profit DESC, ah.level ASC
LIMIT 10;
