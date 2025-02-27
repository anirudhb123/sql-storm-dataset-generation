
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        i_item_id, 
        i_item_desc,
        i_current_price,
        (SELECT AVG(total_sales) FROM sales_data) AS avg_sales
    FROM 
        item 
    WHERE 
        i_current_price > (SELECT AVG(i_current_price) FROM item)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(ws.ws_sales_price) AS max_sales_price,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COALESCE(subquery.recent_orders, 0) AS recent_orders_count
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        ws_ship_customer_sk, 
        COUNT(*) AS recent_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_ship_customer_sk
) AS subquery ON c.c_customer_sk = subquery.ws_ship_customer_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM sales_data sd
        WHERE sd.ws_item_sk = ws.ws_item_sk AND sd.total_sales > (SELECT AVG(total_sales) FROM sales_data)
    )
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
