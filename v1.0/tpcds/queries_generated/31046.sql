
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_current_price,
           0 AS depth
    FROM item
    WHERE i_current_price IS NOT NULL

    UNION ALL

    SELECT ih.i_item_sk, ih.i_item_id, ih.i_product_name, ih.i_current_price,
           depth + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.depth < 5
),
sales_summary AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           MAX(ws_sold_date_sk) AS last_sold_date_sk
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT c_customer_sk, DATEDIFF(CURDATE(), STR_TO_DATE(CONCAT(c_birth_year, '-', c_birth_month, '-', c_birth_day), '%Y-%m-%d')) AS age,
           cd_gender, cd_marital_status, cd_credit_rating,
           CASE
               WHEN cd_buy_potential IS NULL THEN 'UNKNOWN'
               ELSE cd_buy_potential
           END AS buy_potential
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
warehouse_stats AS (
    SELECT w.w_warehouse_sk, COUNT(s.s_store_sk) AS total_stores,
           SUM(s.s_floor_space) AS total_floor_space
    FROM warehouse w
    LEFT JOIN store s ON s.s_store_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
final_report AS (
    SELECT ih.i_item_id, ih.i_product_name, ih.i_current_price, ss.total_quantity,
           ss.total_sales, ci.age, ci.cd_gender, ci.buy_potential,
           ws.total_stores, ws.total_floor_space
    FROM item_hierarchy ih
    JOIN sales_summary ss ON ih.i_item_sk = ss.ws_item_sk
    JOIN customer_info ci ON ci.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    JOIN warehouse_stats ws ON ws.w_warehouse_sk = (SELECT MIN(w_warehouse_sk) FROM warehouse)
)
SELECT fr.*, 
       CASE 
           WHEN fr.total_sales > 100000 THEN 'High Performance'
           WHEN fr.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Performance'
           ELSE 'Low Performance'
       END AS performance_category
FROM final_report fr
WHERE fr.age BETWEEN 18 AND 65
ORDER BY fr.total_sales DESC
LIMIT 100;
