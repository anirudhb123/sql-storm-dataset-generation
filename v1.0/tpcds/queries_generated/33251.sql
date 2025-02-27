
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_customer_sk,
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        w.ws_customer_sk,
        w.ws_item_sk,
        w.ws_order_number,
        w.ws_sold_date_sk,
        w.ws_quantity,
        w.ws_net_profit,
        sd.level + 1
    FROM web_sales w
    INNER JOIN sales_data sd ON w.ws_order_number = sd.ws_order_number
    WHERE sd.level < 5 
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sd.ws_net_profit) DESC) AS rank
FROM customer c
LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_customer_sk
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING total_quantity > (
    SELECT AVG(total_quantity) FROM (
        SELECT SUM(ws_quantity) AS total_quantity
        FROM web_sales
        GROUP BY ws_customer_sk
    ) AS avg_sales
) OR COUNT(DISTINCT sd.ws_order_number) > 1
ORDER BY total_net_profit DESC
LIMIT 10;
