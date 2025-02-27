
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_month ORDER BY c.c_customer_sk) as row_num,
        CASE 
            WHEN c.c_birth_month BETWEEN 1 AND 6 THEN 'First Half'
            WHEN c.c_birth_month BETWEEN 7 AND 12 THEN 'Second Half'
            ELSE 'Unknown'
        END AS birth_half
    FROM 
        customer c
    WHERE 
        c.c_birth_month IS NOT NULL
), 
promotion_stats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(distinct ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(ws.ws_net_profit) AS min_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
), 
store_performance AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.birth_half,
    ps.total_orders,
    ps.total_revenue,
    sp.total_sales,
    COALESCE(sp.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN ps.max_profit IS NULL THEN 'No Profit'
        ELSE CAST(ps.max_profit AS VARCHAR)
    END AS max_promo_profit
FROM 
    customer_hierarchy ch
LEFT JOIN 
    promotion_stats ps ON ch.row_num = (SELECT MIN(row_num) FROM customer_hierarchy WHERE c_birth_month = ch.c_birth_month)
LEFT JOIN 
    store_performance sp ON sp.total_transactions > 10
WHERE 
    ch.c_birth_month IS NOT NULL
AND 
    (ch.c_last_name LIKE '%son%' OR ch.c_last_name LIKE '%o%')
ORDER BY 
    ch.c_birth_month ASC, 
    ps.total_revenue DESC
LIMIT 100;
