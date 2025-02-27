
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > (SELECT AVG(ws_inner.ws_net_profit) FROM web_sales ws_inner WHERE ws_inner.ws_item_sk = ws.ws_item_sk)
),
filtered_sales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    ca.ca_city,
    SUM(fs.ws_quantity) AS total_quantity,
    AVG(fs.ws_net_profit) AS avg_net_profit,
    CASE 
        WHEN COUNT(DISTINCT fs.ws_item_sk) IS NULL THEN 'No items found'
        ELSE CAST(COUNT(DISTINCT fs.ws_item_sk) AS varchar(20))
    END AS unique_items_count,
    COALESCE(MAX(fs.ws_net_profit), 0) AS max_net_profit,
    COUNT(fs.ws_order_number) FILTER (WHERE fs.ws_net_profit < 0) AS negative_profit_orders
FROM 
    filtered_sales fs
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_order_number = fs.ws_order_number)
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    total_quantity >= (SELECT AVG(total_qty) FROM (SELECT SUM(fs.ws_quantity) AS total_qty FROM filtered_sales fs GROUP BY fs.ws_order_number) AS avg_qty)
ORDER BY 
    avg_net_profit DESC
LIMIT 10;

