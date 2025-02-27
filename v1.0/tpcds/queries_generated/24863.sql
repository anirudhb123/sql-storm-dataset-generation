
WITH RECURSIVE customer_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
promotions AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_discount_active,
           p.p_start_date_sk,
           p.p_end_date_sk,
           LEAD(p.p_discount_active, 1) OVER (ORDER BY p.p_start_date_sk) AS next_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
item_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
combined_data AS (
    SELECT cd.c_customer_sk,
           cd.c_first_name,
           cd.c_last_name,
           cd.cd_gender,
           ps.total_sales,
           ps.order_count,
           COALESCE(ps.total_sales, 0) AS total_sales,
           CASE WHEN ps.total_sales IS NULL OR ps.total_sales < 1000 THEN 'Low' ELSE 'High' END AS sales_category
    FROM customer_data cd
    LEFT JOIN item_sales ps ON cd.c_customer_sk = ps.ws_item_sk
)
SELECT cd.c_first_name,
       cd.c_last_name,
       cd.cd_gender,
       pl.p_promo_id,
       CASE 
           WHEN pl.next_discount_active IS NULL THEN 'No Successor'
           ELSE pl.next_discount_active
       END AS subsequent_discount_status,
       cd.sales_category,
       SUM(NULLIF(ps.total_sales, 0)) OVER (PARTITION BY cd.cd_gender ORDER BY cd.c_first_name DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM combined_data cd
LEFT JOIN promotions pl ON cd.c_customer_sk = pl.p_promo_sk
WHERE cd.total_sales IS NOT NULL OR cd.total_sales IS NULL
ORDER BY cd.c_gender, cumulative_sales DESC
FETCH FIRST 100 ROWS ONLY;
