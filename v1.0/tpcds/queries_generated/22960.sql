
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_current_cdemo_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_birth_year >= 1980
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_current_cdemo_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
ImpactfulReturns AS (
    SELECT sr2.sr_returned_date_sk, sr2.sr_item_sk, sr2.sr_return_quantity, sr2.sr_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_return_quantity > (
        SELECT AVG(sr_return_quantity) * 1.5
        FROM store_returns
    )
),
TotalShippingCosts AS (
    SELECT sm.sm_ship_mode_id, SUM(ws.ws_net_paid_inc_ship) AS total_shipping
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
),
PromotionsApplied AS (
    SELECT p.p_promo_id, COUNT(ws.ws_order_number) AS promo_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY p.p_promo_id
),
LastPurchaseDates AS (
    SELECT c.c_customer_sk, MAX(da.d_date) AS last_purchase_date
    FROM customer c
    JOIN date_dim da ON c.c_first_sales_date_sk = da.d_date_sk
    WHERE da.d_year = 2023
    GROUP BY c.c_customer_sk
),
FinalSalesData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ch.level,
        COALESCE(lsd.last_purchase_date, 'N/A') AS last_purchase_date,
        ts.total_shipping,
        pa.promo_count
    FROM CustomerHierarchy ch
    LEFT JOIN LastPurchaseDates lsd ON ch.c_customer_sk = lsd.c_customer_sk
    JOIN TotalShippingCosts ts ON true
    JOIN PromotionsApplied pa ON true
)
SELECT *
FROM FinalSalesData
WHERE (level = 3 OR total_shipping > 100) AND (promo_count IS NULL OR promo_count > 5)
ORDER BY total_shipping DESC, last_purchase_date DESC NULLS LAST;
