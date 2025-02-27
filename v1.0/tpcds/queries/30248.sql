
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) - 30
            FROM date_dim d
        )
    GROUP BY 
        ws.ws_item_sk
),
store_activity AS (
    SELECT
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) - 30
            FROM date_dim d
        )
    GROUP BY 
        s.s_store_id
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.orders_count,
    cs.total_spent,
    MAX(sa.total_sales) AS highest_store_sales,
    ss.total_quantity AS best_selling_quantity,
    ss.total_net_profit AS best_selling_profit
FROM 
    customer_stats cs
LEFT JOIN store_activity sa ON sa.s_store_id IN (
    SELECT s.s_store_id FROM store s WHERE s.s_city = 'Los Angeles'
)
JOIN sales_summary ss ON ss.ws_item_sk = (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = cs.c_customer_sk
    ORDER BY ws.ws_net_profit DESC
    FETCH FIRST 1 ROW ONLY
)
WHERE 
    cs.last_purchase_date >= (
        SELECT MAX(d.d_date_sk) - 30 FROM date_dim d
    )
GROUP BY 
    cs.c_customer_sk, cs.orders_count, cs.total_spent, ss.total_quantity, ss.total_net_profit
ORDER BY 
    cs.total_spent DESC 
FETCH FIRST 100 ROWS ONLY;
