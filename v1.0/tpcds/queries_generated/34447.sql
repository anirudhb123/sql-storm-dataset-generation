
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           hd.hd_income_band_sk,
           0 AS level
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           hd.hd_income_band_sk,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_hdemo_sk = ch.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ch.level < 2
),
item_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sales,
           AVG(ws.ws_sales_price) AS avg_price,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
sales_by_income AS (
    SELECT ch.c_customer_sk,
           ch.c_first_name,
           ch.c_last_name,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(is.total_sales) AS total_sales
    FROM customer_hierarchy ch
    LEFT JOIN item_sales is ON is.ws_item_sk =
           (SELECT i.i_item_sk
            FROM item i
            WHERE i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
            LIMIT 1)
    JOIN income_band ib ON ch.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT s.c_first_name,
       s.c_last_name,
       s.ib_lower_bound,
       s.ib_upper_bound,
       COALESCE(s.total_sales, 0) AS sales_amount,
       CASE 
           WHEN s.total_sales IS NULL THEN 'No Sales'
           ELSE 'Sales Recorded'
       END AS sales_status
FROM sales_by_income s
FULL OUTER JOIN customer_hierarchy ch ON s.c_customer_sk = ch.c_customer_sk
WHERE (s.total_sales > 100 OR s.total_sales IS NULL)
ORDER BY s.s_total_sales DESC NULLS LAST
LIMIT 100;
