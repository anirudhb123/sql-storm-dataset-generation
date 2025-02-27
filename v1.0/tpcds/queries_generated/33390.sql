
WITH RECURSIVE sales_history AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        LEAD(ws_net_profit) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS next_profit
    FROM 
        web_sales
), 
customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_price,
        c.c_gender,
        c.c_preferred_cust_flag
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_gender, c.c_preferred_cust_flag
),
filtered_item_stats AS (
    SELECT
        i.i_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws_sales_price > 100
    GROUP BY 
        i.i_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_profit,
    fs.total_quantity_sold,
    fs.total_net_profit,
    CASE 
        WHEN cs.total_profit IS NULL THEN 'No Orders'
        WHEN fs.total_quantity_sold IS NULL THEN 'No Items Sold'
        ELSE 'Active'
    END AS sales_status,
    COALESCE((
        SELECT COUNT(*)
        FROM store s
        WHERE s.s_number_employees > 50
        AND EXISTS (
            SELECT 1 FROM store_sales ss
            WHERE ss.ss_store_sk = s.s_store_sk
            AND ss.ss_net_profit > 1000
        )
    ), 0) AS active_stores
FROM 
    customer_stats cs
FULL OUTER JOIN 
    filtered_item_stats fs ON cs.c_customer_sk = fs.i_item_sk
WHERE 
    cs.total_orders > 5
    OR fs.total_quantity_sold > 10
ORDER BY 
    cs.total_profit DESC NULLS LAST
LIMIT 100;
