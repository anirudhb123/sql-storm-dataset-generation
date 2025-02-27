
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           CAST(CONCAT(c_first_name, ' ', c_last_name) AS VARCHAR(60)) AS full_name,
           1 AS lvl
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           CAST(CONCAT(c.c_first_name, ' ', c.c_last_name) AS VARCHAR(60)),
           ct.lvl + 1
    FROM customer c
    JOIN customer_tree ct ON ct.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ct.lvl < 5
),
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(CASE WHEN ws.ws_quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity_count
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND (cd.cd_marital_status IS NOT NULL OR cd.cd_marital_status IN ('S', 'M'))
      AND cd.cd_dep_count >= 2
    GROUP BY ws.ws_item_sk
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk
)
SELECT 
    ct.full_name,
    sd.total_sales,
    sd.total_profit,
    sd.total_tax,
    ps.promo_order_count,
    ps.avg_net_paid
FROM customer_tree ct
FULL OUTER JOIN sales_data sd ON ct.c_customer_sk = sd.ws_item_sk
FULL OUTER JOIN promotion_summary ps ON sd.ws_item_sk = ps.p_promo_sk
WHERE (sd.total_sales > 0 OR sd.total_profit IS NOT NULL)
  AND (ps.promo_order_count IS NULL OR ps.promo_order_count > 5)
ORDER BY ct.lvl DESC, sd.total_profit DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
