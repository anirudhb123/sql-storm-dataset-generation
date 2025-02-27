
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COALESCE(SUM(ss.net_profit), 0) AS total_store_sales,
           COALESCE(SUM(ws.net_profit), 0) AS total_web_sales,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ss.net_profit), 0) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_store_sales DESC) AS store_sales_rank,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_web_sales DESC) AS web_sales_rank
    FROM customer_info
)
SELECT t.c_customer_sk, t.c_first_name, t.c_last_name, t.cd_gender,
       CASE
           WHEN t.store_sales_rank <= 5 THEN 'Top Store Customer'
           WHEN t.web_sales_rank <= 5 THEN 'Top Web Customer'
           ELSE 'Regular Customer'
       END AS customer_type,
       CASE
           WHEN t.store_sales_rank = 1 THEN 'Gold Tier'
           WHEN t.web_sales_rank = 1 THEN 'Silver Tier'
           ELSE 'Bronze Tier'
       END AS sales_tier,
       STRING_AGG(DISTINCT p.p_promo_name || ' (' || CAST(p.p_cost AS VARCHAR) || ')', ', ') AS active_promotions
FROM top_customers t
LEFT JOIN promotion p ON p.p_item_sk IN (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = t.c_customer_sk
    UNION
    SELECT ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_customer_sk = t.c_customer_sk
)
WHERE t.total_store_sales > 1 AND t.total_web_sales < 10
GROUP BY t.c_customer_sk, t.c_first_name, t.c_last_name, t.cd_gender, t.store_sales_rank, t.web_sales_rank
HAVING COUNT(*)
ORDER BY t.total_store_sales DESC, t.total_web_sales ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
