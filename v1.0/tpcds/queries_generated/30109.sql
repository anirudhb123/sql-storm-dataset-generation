
WITH RECURSIVE Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_discount_active,
        COUNT(ws_order_number) AS promo_count
    FROM promotion p
    JOIN web_sales w ON p.p_promo_sk = w.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_discount_active
),
Combined AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        si.total_sales,
        p.promo_count
    FROM CustomerInfo c
    LEFT JOIN Sales si ON c.c_customer_sk = si.ws_item_sk
    LEFT JOIN Promotions p ON p.promo_count > 10
    WHERE c.rank = 1 AND si.total_sales IS NOT NULL
)
SELECT
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(promo_count) AS max_promos
FROM Combined
WHERE total_sales > (SELECT AVG(total_sales) FROM Sales);
