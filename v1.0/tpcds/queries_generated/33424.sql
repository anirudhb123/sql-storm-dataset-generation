
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
promotions_summary AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        promotions p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(ws_sold_date_sk) FROM web_sales) 
        AND p.p_end_date_sk >= (SELECT MIN(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
stores_performance AS (
    SELECT 
        s.s_store_sk,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        s.s_store_sk
)

SELECT 
    cs.c_customer_sk,
    ps.p_promo_name,
    ss.total_transactions,
    ss.total_profit,
    cs.order_count,
    cs.total_spent
FROM 
    customer_stats cs
CROSS JOIN 
    promotions_summary ps
LEFT JOIN 
    stores_performance ss ON cs.order_count >= 1
WHERE 
    cs.total_spent > 1000
    AND cs.order_count > 5
    AND ps.total_sales IS NOT NULL
ORDER BY 
    ss.total_profit DESC
LIMIT 50;
