
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity,
        ws_net_profit,
        CAST(ws_net_profit AS decimal(10,2)) AS cumulative_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= 2459480 -- Example date
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_net_profit,
        CAST(s.cumulative_profit + ws.ws_net_profit AS decimal(10,2)) AS cumulative_profit
    FROM web_sales ws
    JOIN Sales_CTE s ON ws.ws_sold_date_sk = s.ws_sold_date_sk + 1 AND ws.ws_item_sk = s.ws_item_sk
),
Ranked_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ws_net_profit) AS total_profit,
        COUNT(DISTINCT s.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_ship_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    d.d_date,
    ca.ca_city,
    ca.ca_state,
    cs.c_customer_id,
    cs.total_profit,
    ss.total_quantity,
    ss.total_net_profit
FROM 
    date_dim d
LEFT JOIN customer_address ca ON d.d_date_sk = ca.ca_address_sk
LEFT JOIN Customer_Sales cs ON cs.total_profit > 1000
LEFT JOIN Ranked_Sales ss ON ss.ws_item_sk = cs.total_profit
WHERE 
    d.d_year = 2023
    AND (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
ORDER BY 
    d.d_date, cs.total_profit DESC;
