
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_current_price, 0 AS level
    FROM item
    WHERE i_item_sk IN (
        SELECT i_item_sk 
        FROM store_sales 
        WHERE ss_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date = DATE '2002-10-01'
        )
    )
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price * 0.9 AS i_current_price, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk + 1
    WHERE ih.level < 5
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_within_city,
    CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Profit'
        WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    STRING_AGG(DISTINCT i_product_name || ' (' || i_current_price || ')', ', ') AS products_sold,
    COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_cdemo_sk
WHERE ca.ca_country = 'USA'
AND ca.ca_state IN ('NY', 'CA')
AND ws.ws_sold_date_sk >= (
    SELECT MAX(d_date_sk) 
    FROM date_dim 
    WHERE d_date < DATE '2002-10-01' - INTERVAL '1 YEAR'
)
GROUP BY 
    c.c_customer_id, 
    ca.ca_city, 
    hd.hd_buy_potential
HAVING SUM(ws.ws_net_profit) IS NOT NULL
ORDER BY total_net_profit DESC, ca.ca_city ASC;
