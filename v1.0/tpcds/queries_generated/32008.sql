
WITH RECURSIVE top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_net_paid) > 10000
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
items_sold AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        top_customers tc ON ws.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
high_profit_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        items.total_profit
    FROM 
        item i
    JOIN 
        items_sold items ON i.i_item_sk = items.ws_item_sk
    WHERE 
        items.total_profit > 500
),
customer_address_info AS (
    SELECT 
        ca.*, 
        cd.cd_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(tc.c_customer_sk) AS customer_count,
    COUNT(DISTINCT hi.i_item_id) AS items_with_high_profit,
    AVG(hi.total_profit) AS average_profit_per_item
FROM 
    customer_address_info ca
LEFT JOIN 
    top_customers tc ON ca.ca_address_sk = tc.c_customer_sk
LEFT JOIN 
    high_profit_items hi ON tc.c_customer_sk IN (
        SELECT DISTINCT ws.ws_ship_customer_sk 
        FROM web_sales ws 
        WHERE ws.ws_item_sk = hi.i_item_sk
    )
WHERE 
    ca.ca_state IS NOT NULL 
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    customer_count > 5
ORDER BY 
    average_profit_per_item DESC;
