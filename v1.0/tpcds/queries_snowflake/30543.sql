
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        1 AS depth
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
    
    UNION ALL
    
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        (sd.ws_net_profit + ws.ws_net_profit) AS ws_net_profit,
        ws.ws_sold_date_sk,
        depth + 1
    FROM web_sales ws
    JOIN sales_data sd ON sd.ws_item_sk = ws.ws_item_sk AND sd.depth < 3
    WHERE ws.ws_net_profit > 0
), profit_analysis AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY item.i_item_id ORDER BY SUM(sd.ws_net_profit) DESC) AS profit_rank
    FROM sales_data sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    pa.i_item_id,
    pa.total_profit,
    pa.order_count
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN profit_analysis pa ON c.c_customer_sk = pa.order_count
WHERE ca.ca_state IN ('CA', 'NY')
    AND pa.total_profit > (
        SELECT AVG(total_profit) 
        FROM profit_analysis 
        WHERE profit_rank < 10
    )
ORDER BY ca.ca_city, pa.total_profit DESC
LIMIT 100;
