
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_current_price, i_wholesale_cost, 1 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.item_sk, i.i_item_id, i.i_product_name, i.i_current_price, i.i_wholesale_cost, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.item_sk = ih.i_item_sk
    WHERE i.i_item_sk IS NOT NULL
),
CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           HD.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics HD ON c.c_customer_sk = HD.hd_demo_sk
),
SalesDetails AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws 
    GROUP BY ws.ws_item_sk
),
PromotionDetails AS (
    SELECT p.p_promo_id, COUNT(DISTINCT p.p_item_sk) AS promo_item_count
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(cd.hd_income_band_sk AS VARCHAR)
    END AS income_band,
    ih.i_item_id,
    ih.i_product_name,
    ih.i_current_price,
    COALESCE(sd.total_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_profit, 0) AS total_sales_profit,
    pd.promo_item_count
FROM CustomerDetails cd
LEFT JOIN ItemHierarchy ih ON cd.c_customer_sk = ih.i_item_sk
LEFT JOIN SalesDetails sd ON ih.i_item_sk = sd.ws_item_sk
LEFT JOIN PromotionDetails pd ON ih.i_item_sk = pd.promo_item_count
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
  AND (cd.cd_marital_status = 'S' AND cd.hd_income_band_sk IS NOT NULL)
ORDER BY cd.c_last_name, cd.c_first_name, ih.i_product_name 
LIMIT 100
```
