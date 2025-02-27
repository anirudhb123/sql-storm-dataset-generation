
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           COALESCE(a.ca_city, 'Unknown') AS city,
           ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS rn
    FROM customer c
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_customer_id, ch.c_first_name, ch.c_last_name,
           COALESCE(a.ca_city, 'Unknown') AS city,
           rn + 1 AS rn
    FROM CustomerHierarchy ch
    JOIN customer_address a ON ch.c_customer_sk = a.ca_address_sk
    WHERE rn < 5
),
SalesAggregates AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_sales_price) AS avg_price,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
PromotionsInfo AS (
    SELECT p.p_promo_id,
           p.p_promo_name,
           COUNT(DISTINCT p.p_item_sk) AS item_count,
           MAX(p.p_cost) AS max_cost
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name
),
ConversionRates AS (
    SELECT ch.c_customer_id,
           COALESCE(sa.total_quantity, 0) AS total_quantity,
           COALESCE(sa.order_count, 0) AS order_count,
           CASE WHEN sa.order_count > 0 THEN 
               (COALESCE(sa.total_quantity, 0) * 1.0 / sa.order_count) 
           ELSE 0 END AS average_quantity_per_order
    FROM CustomerHierarchy ch
    LEFT JOIN SalesAggregates sa ON ch.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT cr.c_customer_id,
       cr.total_quantity,
       cr.order_count,
       cr.average_quantity_per_order,
       pi.p_promo_id,
       pi.p_promo_name,
       pi.item_count,
       pi.max_cost
FROM ConversionRates cr
FULL OUTER JOIN PromotionsInfo pi ON cr.order_count > 0 AND cr.order_count = pi.item_count
WHERE cr.total_quantity IS NOT NULL OR pi.item_count IS NOT NULL
ORDER BY cr.total_quantity DESC NULLS LAST, pi.max_cost DESC NULLS LAST
LIMIT 50;
