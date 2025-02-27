
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_credit_rating, 
           COALESCE(COUNT(DISTINCT s.s_store_sk), 0) AS store_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s ON s.s_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_credit_rating
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.cd_marital_status, ch.cd_credit_rating, 
           ch.store_count + COALESCE(COUNT(DISTINCT s.s_store_sk), 0)
    FROM CustomerHierarchy ch
    JOIN store s ON s.s_customer_sk = ch.c_customer_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
             ch.cd_marital_status, ch.cd_credit_rating, ch.store_count
),
SalesData AS (
    SELECT ws.ws_ship_date_sk, ws.ws_item_sk, 
           SUM(ws.ws_sales_price) AS total_sales,
           SUM(ws.ws_quantity) AS total_quantity,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= 2459655  -- Filter for a specific date range
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
PromotionData AS (
    SELECT p.p_promo_id, 
           COUNT(DISTINCT ps.ps_item_sk) AS promo_item_count,
           STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_names
    FROM promotion p
    JOIN promotion p2 ON p.p_promo_id = p2.p_promo_id
    WHERE p.p_start_date_sk <= 2459655 AND p.p_end_date_sk >= 2459655
    GROUP BY p.p_promo_id
)
SELECT ch.c_first_name, ch.c_last_name, ch.cd_credit_rating, 
       ROUND(SUM(sd.total_sales), 2) AS total_sales,
       SUM(sd.total_quantity) AS total_quantity,
       MAX(pd.promo_item_count) AS top_promo_item_count,
       MAX(pd.promo_names) AS top_promotions
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON sd.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_item_desc LIKE '%gadget%')
LEFT JOIN PromotionData pd ON pd.promo_item_count > 5
WHERE ch.cd_marital_status = 'M'
GROUP BY ch.c_first_name, ch.c_last_name, ch.cd_credit_rating
HAVING SUM(sd.total_sales) > 1000
ORDER BY total_sales DESC
LIMIT 10;
