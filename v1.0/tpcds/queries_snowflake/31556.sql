
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           sh.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
    WHERE sh.level < 5
),
sales_summary AS (
    SELECT sh.c_customer_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(ws.ws_order_number) AS total_orders
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY sh.c_customer_sk
),
promotion_summary AS (
    SELECT p.p_promo_id, p.p_promo_name, COUNT(cs.cs_order_number) AS promo_sales_count
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE p.p_start_date_sk < 20000
    GROUP BY p.p_promo_id, p.p_promo_name
)

SELECT ss.c_customer_sk, ss.total_sales, ss.total_orders,
       COALESCE(ps.promo_sales_count, 0) AS promo_sales_count,
       (CASE 
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            WHEN ss.total_sales > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END) AS customer_value_category
FROM sales_summary ss
FULL OUTER JOIN promotion_summary ps ON ss.c_customer_sk = ps.promo_sales_count
WHERE ss.total_orders IS NOT NULL
  AND (ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary) OR ps.promo_sales_count > 5)
ORDER BY ss.total_sales DESC, ps.promo_sales_count ASC;
