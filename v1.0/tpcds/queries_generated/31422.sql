
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-01-31'
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    INNER JOIN DateRange dr ON d.d_date_sk = dr.d_date_sk + 1
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN DateRange dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_item_sk
),
PromotionData AS (
    SELECT 
        p.p_promo_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk
),
FinalResult AS (
    SELECT 
        s.sd_item_sk,
        CASE 
            WHEN sd_pro.total_profit IS NULL THEN 0 
            ELSE sd_pro.total_profit 
        END AS total_profit,
        COALESCE(pr.total_net_paid, 0) AS total_promo_net_paid
    FROM SalesData sd_pro
    LEFT JOIN PromotionData pr ON sd_pro.ws_item_sk = pr.p_promo_sk
)
SELECT 
    f.sd_item_sk,
    f.total_profit,
    f.total_promo_net_paid,
    CASE 
        WHEN f.total_profit > f.total_promo_net_paid THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_indicator
FROM FinalResult f
WHERE f.total_profit > AVG(f.total_profit) OVER ()
ORDER BY f.total_profit DESC;
