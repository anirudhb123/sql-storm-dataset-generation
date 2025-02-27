
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        total_spent,
        order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY total_spent DESC) AS rank_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_data d ON d.c_customer_sk = c.c_customer_sk
    WHERE total_spent > (SELECT AVG(total_spent) FROM customer_data)
),
store_data AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid_inc_tax) AS store_revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promotion_orders,
        SUM(ws.ws_net_paid) AS promo_revenue
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
final_ranking AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_spent,
        hvc.order_count,
        hvc.rank_gender,
        sd.store_revenue,
        ps.promo_revenue,
        COALESCE(sd.store_revenue / NULLIF(ps.promo_revenue, 0), 0) AS revenue_ratio
    FROM high_value_customers hvc
    LEFT JOIN store_data sd ON hvc.c_customer_sk = (SELECT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_store_sk = sd.s_store_sk LIMIT 1)
    LEFT JOIN promotion_summary ps ON ps.promotion_orders > 0
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.rank_gender,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(c.order_count, 0) AS order_count,
    COALESCE(sd.store_revenue, 0) AS store_revenue,
    COALESCE(ps.promo_revenue, 0) AS promo_revenue,
    COALESCE(c.revenue_ratio, 0) AS revenue_ratio,
    CASE 
        WHEN c.rank_gender = 1 THEN 'Top Spender'
        WHEN c.rank_gender < 5 THEN 'High Roller'
        ELSE 'Average Joe'
    END AS customer_tier
FROM final_ranking c
LEFT JOIN store_data sd ON c.c_customer_sk = sd.s_store_sk
LEFT JOIN promotion_summary ps ON ps.promo_revenue IS NOT NULL
ORDER BY c.total_spent DESC, c.order_count ASC, customer_tier;
