
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_wb_promo_sk,
        ws_item_sk,
        ws_sales_price,
        1 AS level,
        ws_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT MAX(ws_sold_date_sk) 
            FROM web_sales
        )
    UNION ALL
    SELECT 
        ws.ws_wb_promo_sk,
        ws.ws_item_sk,
        ws.ws_sales_price * 0.9 AS ws_sales_price,
        sh.level + 1,
        ws.ws_net_profit * 1.05 AS ws_net_profit
    FROM 
        web_sales ws
    JOIN 
        sales_hierarchy sh ON ws.ws_item_sk = sh.ws_item_sk
    WHERE 
        sh.level < 5
),
item_summary AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(d.moy) AS total_months
    FROM 
        customer c
    JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        date_dim d ON d.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        ca_state
)
SELECT 
    ih.i_item_id,
    ih.total_orders,
    ih.total_profit,
    ih.avg_sales_price,
    asu.ca_state,
    asu.customer_count,
    asu.total_months
FROM 
    item_summary ih
JOIN 
    address_summary asu ON asu.customer_count > 100
ORDER BY 
    ih.total_profit DESC
LIMIT 10;
