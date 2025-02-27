
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
active_promotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name, 
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim) 
        AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
top_sales_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS top_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.order_count > 1
)
SELECT 
    tsc.c_customer_id,
    tsc.c_first_name,
    tsc.c_last_name,
    tsc.total_profit,
    ap.promo_usage,
    COALESCE(tsc.total_profit / NULLIF(ap.promo_usage, 0), 0) AS profit_per_promo
FROM 
    top_sales_customers tsc
LEFT JOIN 
    active_promotions ap ON tsc.total_profit > 0
WHERE 
   tsc.top_rank <= 10 
   AND (ap.promo_usage IS NULL OR ap.promo_usage > 5)
ORDER BY 
    tsc.total_profit DESC
FETCH FIRST 20 ROWS ONLY
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    SUM(tsc.total_profit) AS total_profit,
    SUM(ap.promo_usage) AS promo_usage,
    COALESCE(SUM(tsc.total_profit) / NULLIF(SUM(ap.promo_usage), 0), 0) AS profit_per_promo
FROM 
    top_sales_customers tsc
LEFT JOIN 
    active_promotions ap ON tsc.total_profit > 0;
