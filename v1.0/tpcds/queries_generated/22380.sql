
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_profit,
        COUNT(*) OVER (PARTITION BY ws.web_site_sk) AS total_orders
    FROM 
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000 
        AND c.c_country IS NOT NULL
),
sales_with_buffer AS (
    SELECT 
        rs.web_site_id,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.rank_profit,
        rs.total_profit,
        CASE 
            WHEN rs.total_orders > 0 THEN (rs.total_profit / rs.total_orders)
            ELSE NULL
        END AS avg_profit_per_order,
        CASE 
            WHEN rs.total_profit >= 10000 THEN 'High Performer'
            WHEN rs.total_profit < 5000 THEN 'Low Performer'
            ELSE 'Medium Performer'
        END AS performance_band
    FROM 
        ranked_sales rs
)
SELECT 
    swb.web_site_id,
    swb.ws_order_number,
    swb.ws_quantity,
    swb.rank_profit,
    swb.total_profit,
    swb.avg_profit_per_order,
    swb.performance_band,
    COALESCE((
        SELECT 
            MAX(CASE 
                WHEN sm.sm_type = 'Express' AND swb.ws_quantity >= 5 THEN sm.sm_carrier
                ELSE NULL 
            END)
        FROM 
            ship_mode sm 
        JOIN 
            store_sales ss ON swb.ws_order_number = ss.ss_ticket_number
        WHERE 
            ss.ss_item_sk IN (
                SELECT 
                    i.i_item_sk 
                FROM 
                    item i 
                WHERE 
                    i.i_current_price BETWEEN 20 AND 100
            )
    ), 'Standard') AS shipping_method
FROM 
    sales_with_buffer swb
WHERE 
    swb.rank_profit <= 5
    AND swb.total_profit IS NOT NULL
ORDER BY 
    swb.total_profit DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
