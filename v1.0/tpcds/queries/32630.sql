
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )

    UNION ALL

    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cte.level + 1
    FROM web_sales ws
    JOIN SalesCTE cte ON ws.ws_order_number = cte.ws_order_number
    WHERE ws.ws_quantity < cte.ws_quantity
)

SELECT 
    s.ws_item_sk,
    SUM(s.ws_quantity) AS total_quantity,
    AVG(s.ws_sales_price) AS avg_sales_price,
    SUM(s.ws_net_profit) AS total_net_profit,
    CASE 
        WHEN SUM(s.ws_quantity) > 100 THEN 'High Seller'
        WHEN SUM(s.ws_quantity) BETWEEN 50 AND 100 THEN 'Moderate Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM SalesCTE s
LEFT JOIN item i ON s.ws_item_sk = i.i_item_sk
LEFT JOIN store st ON st.s_store_sk = (
    SELECT sr_store_sk 
    FROM store_returns 
    WHERE sr_item_sk = s.ws_item_sk 
    GROUP BY sr_store_sk
    HAVING COUNT(sr_item_sk) > 0
)
WHERE i.i_current_price > 20.00
GROUP BY s.ws_item_sk
ORDER BY total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
