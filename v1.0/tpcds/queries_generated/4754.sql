
WITH RevenueCTE AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws.web_site_id
),
PromoCTE AS (
    SELECT 
        ps.p_promo_id,
        p.p_discount_active,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_net_paid_inc_tax ELSE 0 END) AS promo_revenue
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY ps.p_promo_id, p.p_discount_active
),
RankedRevenue AS (
    SELECT
        web_site_id,
        total_revenue,
        order_count,
        avg_profit,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RevenueCTE
),
FinalReport AS (
    SELECT
        r.web_site_id,
        r.total_revenue,
        r.order_count,
        r.avg_profit,
        p.promo_revenue,
        CASE 
            WHEN r.total_revenue IS NULL THEN 'Revenue Not Available'
            WHEN r.total_revenue > 100000 THEN 'Top Performer'
            ELSE 'Needs Improvement'
        END AS performance_category
    FROM RankedRevenue r
    FULL OUTER JOIN PromoCTE p ON r.web_site_id = p.promo_id
)
SELECT 
    fr.web_site_id,
    fr.total_revenue,
    fr.order_count,
    fr.avg_profit,
    COALESCE(fr.promo_revenue, 0) AS promo_revenue,
    fr.performance_category
FROM FinalReport fr
WHERE fr.order_count > 10
ORDER BY fr.total_revenue DESC
LIMIT 50;
