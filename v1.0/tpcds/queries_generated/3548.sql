
WITH customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_income_band,
           COALESCE(hd.hd_buy_potential, 'Unknown') AS hd_buy_potential,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_buy_potential
),
sales_summary AS (
    SELECT total_sales,
           CASE
               WHEN total_sales IS NULL THEN 'No Sales'
               WHEN total_sales < 100 THEN 'Low Sales'
               WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
               ELSE 'High Sales'
           END AS sales_category
    FROM customer_info
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ss.sales_category,
       RANK() OVER (PARTITION BY ss.sales_category ORDER BY ci.total_sales DESC) AS sales_rank
FROM customer_info ci
JOIN sales_summary ss ON ci.total_sales = ss.total_sales
WHERE ss.sales_category != 'No Sales'
ORDER BY ss.sales_category, sales_rank;
