
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    WHERE 
        i.i_current_price > 0
),
sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        (SELECT COUNT(DISTINCT wr.returning_customer_sk) 
         FROM web_returns wr 
         WHERE wr.wr_item_sk = i.i_item_sk) AS total_returns
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    GROUP BY 
        i.i_item_id, i.i_item_desc
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.total_quantity_sold,
    s.total_net_profit,
    s.total_orders,
    s.total_returns,
    CASE 
        WHEN s.total_net_profit > 1000 THEN 'High Profit'
        WHEN s.total_net_profit BETWEEN 100 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    (SELECT AVG(total_net_profit) 
     FROM sales_summary 
     WHERE total_orders > 0) AS avg_profit_all_items
FROM 
    sales_summary s
WHERE 
    s.total_quantity_sold > (
        SELECT AVG(total_quantity_sold) 
        FROM sales_summary
    )
ORDER BY 
    s.total_net_profit DESC
LIMIT 10;
