
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales) 
    GROUP BY 
        ws_item_sk
),
customer_orders AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        sa.total_profit,
        co.total_orders,
        co.average_order_value,
        RANK() OVER (PARTITION BY co.total_orders ORDER BY sa.total_profit DESC) AS profit_rank
    FROM 
        item_sales sa
    INNER JOIN 
        customer_orders co ON sa.ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_sk = sa.ws_item_sk)
)
SELECT 
    ss.ws_item_sk, 
    ss.total_quantity, 
    ss.total_profit,
    ss.total_orders,
    ss.average_order_value,
    CASE 
        WHEN ss.profit_rank IS NULL THEN 'No Orders'
        ELSE CAST(ss.profit_rank AS VARCHAR)
    END AS rank_status
FROM 
    sales_summary ss
LEFT JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 10.00
    AND (ss.total_profit IS NOT NULL OR ss.total_orders IS NOT NULL)
ORDER BY 
    ss.total_profit DESC, 
    ss.total_orders DESC
LIMIT 100;
