
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
      AND ws_quantity > 0

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity + CTE.ws_quantity,
        ws_sales_price,
        ws_net_profit + CTE.ws_net_profit,
        level + 1
    FROM web_sales
    JOIN SalesCTE CTE ON ws_item_sk = CTE.ws_item_sk AND level < 3
)
SELECT 
    ca.ca_country,
    SUM(SALES.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT SALES.ws_order_number) AS total_orders,
    AVG(SALES.ws_quantity) AS average_quantity,
    STRING_AGG(DISTINCT i.i_product_name) AS sold_items
FROM (
    SELECT 
        DISTINCT ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit
    FROM SalesCTE
) SALES
JOIN customer c ON c.c_customer_sk = SALES.ws_order_number
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
JOIN item i ON i.i_item_sk = SALES.ws_item_sk
GROUP BY ca.ca_country
HAVING SUM(SALES.ws_net_profit) > (
    SELECT AVG(ws_net_profit)
    FROM web_sales
    WHERE ws_sold_date_sk IS NOT NULL
)
ORDER BY total_net_profit DESC
LIMIT 10;
