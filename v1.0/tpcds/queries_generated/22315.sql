
WITH sales_stats AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_ship) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
category_sales AS (
    SELECT 
        i.category AS item_category,
        SUM(ws.net_profit) AS category_profit
    FROM web_sales ws
    JOIN item i ON ws.item_sk = i.item_sk
    GROUP BY i.category
),
combined_stats AS (
    SELECT 
        ss.web_site_id,
        ss.total_orders,
        ss.total_profit,
        cs.category_profit,
        ss.avg_order_value,
        CASE 
            WHEN ss.total_profit IS NULL THEN ‘N/A’
            WHEN ss.total_profit > 1000 THEN ‘High Profit’
            ELSE ‘Low Profit’ 
        END AS profit_category
    FROM sales_stats ss
    LEFT JOIN category_sales cs ON ss.web_site_id = cs.item_category
)
SELECT 
    c.customer_id,
    cs.web_site_id,
    cs.total_orders,
    cs.total_profit,
    cs.avg_order_value,
    cs.profit_category,
    COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS full_customer_name,
    CASE 
        WHEN cs.category_profit IS NULL THEN 'No Sales'
        WHEN cs.total_profit < 500 THEN 'Underperforming'
        ELSE 'Performing Well'
    END AS performance_indicator
FROM combined_stats cs
FULL OUTER JOIN customer c ON c.c_current_addr_sk = cs.web_site_id
WHERE cs.total_orders > 0 OR c.c_first_name IS NULL
ORDER BY cs.avg_order_value DESC, cs.total_profit DESC
LIMIT 100;
