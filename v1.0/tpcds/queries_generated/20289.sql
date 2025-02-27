
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        AVG(ws.ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
), 
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        is.total_sold,
        is.total_profit,
        RANK() OVER (ORDER BY is.total_profit DESC) AS profit_rank
    FROM 
        item i
    JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
    WHERE 
        is.total_sold > 0
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ci.ca_street_number || ' ' || ci.ca_street_name AS full_address,
    t.i_product_name,
    COALESCE(cs.total_quantity, 0) AS quantities_purchased,
    t.total_profit,
    CASE 
        WHEN cs.average_net_profit IS NULL THEN 'No Orders'
        ELSE CONCAT('Average Profit: ', ROUND(cs.average_net_profit, 2))
    END AS average_profit_message,
    CASE 
        WHEN t.profit_rank <= 10 THEN 'Top Selling Item'
        ELSE 'Regular Item'
    END AS item_category
FROM 
    customer_sales cs
JOIN 
    customer_address ci ON cs.c_customer_sk = ci.ca_address_sk
JOIN 
    top_items t ON cs.c_customer_sk = (SELECT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = t.i_item_sk ORDER BY ws.ws_quantity DESC LIMIT 1)
WHERE 
    cs.total_quantity > 0
ORDER BY 
    item_category DESC, 
    cs.total_quantity DESC
LIMIT 50
OFFSET 10;
