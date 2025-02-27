
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit, 
        1 AS order_depth
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        ws.order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        (ws.ws_net_profit + cte.ws_net_profit), 
        cte.order_depth + 1
    FROM 
        web_sales ws
    JOIN 
        Sales_CTE cte ON ws_order_number = cte.ws_order_number
    WHERE 
        ws.ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(s.ws_quantity) AS total_quantity_sold, 
    SUM(s.ws_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ws_net_profit) DESC) AS profit_rank,
    MAX(s.total_order_value) AS max_order_value,
    DENSE_RANK() OVER (ORDER BY COUNT(ws_order_number) DESC) AS order_count_rank,
    CASE 
        WHEN SUM(s.ws_net_profit) IS NULL THEN 'No Profit' 
        ELSE 'Profit Earned' 
    END AS profit_status
FROM 
    customer c
LEFT JOIN 
    (SELECT 
         ws.s_ship_customer_sk, 
         SUM(ws.ws_sales_price) AS total_order_value, 
         SUM(ws.ws_net_profit) AS ws_net_profit, 
         ws.ws_order_number, 
         ws.ws_item_sk, 
         ws.ws_quantity
     FROM 
         web_sales ws
     GROUP BY 
         ws.s_ship_customer_sk, ws.ws_order_number, ws.ws_item_sk, ws.ws_quantity) s 
    ON c.c_customer_sk = s.s_ship_customer_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = c.c_customer_sk 
        AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    )
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    SUM(s.ws_quantity) > 1000 
ORDER BY 
    total_net_profit DESC
LIMIT 
    10;
