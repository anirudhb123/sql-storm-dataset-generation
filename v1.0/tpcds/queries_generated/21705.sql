
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS average_order_value,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        cs.average_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS overall_rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_orders > 5  -- Only consider customers with more than 5 orders
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS total_promo_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
    HAVING SUM(ws.ws_net_paid) > 1000
),
RankedPromotions AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_promo_sales DESC) as promo_rank
    FROM Promotions
),
CustomerPromotionStats AS (
    SELECT 
        tc.c_customer_id,
        tp.p_promo_id,
        tp.promo_order_count,
        tp.total_promo_sales,
        CASE 
            WHEN SUM(ws.ws_net_paid) IS NULL THEN 0
            ELSE SUM(ws.ws_net_paid)
        END AS customer_spent_on_promos
    FROM TopCustomers tc
    LEFT JOIN web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
    LEFT JOIN RankedPromotions tp ON ws.ws_order_number IN (
        SELECT ws_order_number 
        FROM web_sales 
        WHERE ws_bill_customer_sk = tc.c_customer_id AND ws_promo_sk IS NOT NULL
    )
    GROUP BY tc.c_customer_id, tp.p_promo_id, tp.promo_order_count, tp.total_promo_sales
),
FinalMetrics AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN cps.promo_order_count IS NOT NULL THEN 1 ELSE 0 END) AS promo_order_count,
        COUNT(DISTINCT cps.promo_order_count) AS unique_promotions_used,
        MAX(cps.customer_spent_on_promos) AS max_spent_on_promos
    FROM TopCustomers c
    LEFT JOIN CustomerPromotionStats cps ON c.c_customer_id = cps.c_customer_id
    GROUP BY c.c_customer_id
)
SELECT 
    fm.c_customer_id,
    fm.promo_order_count,
    fm.unique_promotions_used,
    COALESCE(fm.max_spent_on_promos, 0) AS max_spent_on_promos,
    CASE 
        WHEN fm.unique_promotions_used > 0 THEN 'Promotional Engager'
        ELSE 'Non-Engager'
    END AS engagement_status
FROM FinalMetrics fm
JOIN date_dim dd ON dd.d_date = CURRENT_DATE
WHERE dd.d_weekend = 'Y'  -- Only consider customers active on weekends
ORDER BY fm.max_spent_on_promos DESC, fm.c_customer_id;
