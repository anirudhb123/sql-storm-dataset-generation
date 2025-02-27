
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
), 
promotional_effectiveness AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_revenue,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
income_bracket AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(ws.ws_net_paid) AS avg_spending
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    cs.c_customer_id AS customer_id,
    cs.total_net_paid,
    cs.total_orders,
    CASE 
        WHEN cs.rank = 1 THEN 'Top Customer' 
        WHEN cs.total_orders > 5 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS customer_type,
    COALESCE(pe.promo_order_count, 0) AS promo_used,
    COALESCE(pe.promo_revenue, 0.00) AS promo_revenue,
    ib.avg_spending AS average_income_spending
FROM 
    customer_sales cs
LEFT JOIN 
    promotional_effectiveness pe ON cs.c_customer_id = pe.p_promo_id
LEFT JOIN 
    income_bracket ib ON ib.hd_income_band_sk = (
        SELECT hd.hd_income_band_sk 
        FROM household_demographics hd 
        JOIN customer c2 ON hd.hd_demo_sk = c2.c_current_hdemo_sk 
        WHERE c2.c_customer_id = cs.c_customer_id
        LIMIT 1
    )
WHERE
    (cs.total_net_paid IS NOT NULL OR pe.promo_order_count IS NOT NULL) 
    AND (cs.total_orders IS NOT NULL OR COALESCE(pe.avg_order_value, 0) > 100)
ORDER BY 
    cs.total_net_paid DESC, 
    cs.total_orders ASC;
