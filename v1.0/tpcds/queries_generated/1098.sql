
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c_customer_id,
        total_orders,
        total_spent,
        avg_profit_per_order,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_total_spent
    FROM 
        customer_sales
    WHERE 
        total_spent > 1000
),
promotions_with_sales AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promotion_order_count,
        SUM(ws.ws_net_paid_inc_tax) AS promotion_sales
    FROM 
        promotion p
    INNER JOIN 
        (SELECT DISTINCT ws_order_number, ws_promo_sk FROM web_sales) as ws_promo ON p.p_promo_sk = ws_promo.ws_promo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_order_number = ws_promo.ws_order_number
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    c.c_customer_id,
    hvc.total_orders,
    hvc.total_spent,
    hvc.avg_profit_per_order,
    pws.promotion_order_count,
    pws.promotion_sales
FROM 
    high_value_customers hvc
FULL OUTER JOIN 
    promotions_with_sales pws ON pws.promotion_order_count IS NOT NULL
WHERE 
    hvc.rank_total_spent <= 10 OR pws.promotion_sales IS NOT NULL
ORDER BY 
    hvc.total_spent DESC NULLS LAST, pws.promotion_sales DESC NULLS LAST;
