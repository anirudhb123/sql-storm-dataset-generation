
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        CAST(ws_net_profit AS DECIMAL(10,2)) AS cumulative_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    
    UNION ALL
    
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        CAST(sh.cumulative_profit + ws.ws_net_profit AS DECIMAL(10,2)) AS cumulative_profit,
        sh.level + 1
    FROM web_sales ws
    INNER JOIN sales_hierarchy sh ON ws.ws_order_number = sh.ws_order_number
    WHERE ws.ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),

sales_summary AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_net_profit) AS total_net_profit,
        AVG(s.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT s.ws_order_number) AS total_orders,
        COUNT(DISTINCT s.ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(s.ws_net_profit) DESC) AS sales_rank
    FROM sales_hierarchy s
    GROUP BY s.ws_item_sk
),

promoted_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_net_profit,
        ps.p_discount_active,
        CASE WHEN ps.p_discount_active = 'Y' THEN ss.total_net_profit * 0.9 ELSE ss.total_net_profit END AS adjusted_profit
    FROM sales_summary ss
    LEFT JOIN promotion ps ON ss.ws_item_sk = ps.p_item_sk
    WHERE ss.total_orders > 10
)

SELECT 
    p.ws_item_sk,
    p.total_net_profit,
    p.adjusted_profit,
    CASE 
        WHEN p.adjusted_profit IS NOT NULL THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status
FROM promoted_sales p
WHERE p.adjusted_profit > 10000 OR p.total_net_profit IS NULL
ORDER BY adjusted_profit DESC;
