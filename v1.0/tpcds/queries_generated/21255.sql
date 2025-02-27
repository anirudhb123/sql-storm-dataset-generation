
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           CONCAT('Income Range: $', ib_lower_bound, ' - $', ib_upper_bound) AS income_range
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
),
customer_data AS (
    SELECT c.c_customer_sk, c.c_customer_id,
           cd.cd_gender, cd.cd_marital_status,
           hd.hd_income_band_sk, hd.hd_buy_potential
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
),
sales_data AS (
    SELECT ws.ws_customer_sk, SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales AS ws
    GROUP BY ws.ws_customer_sk
),
average_sales AS (
    SELECT customer_data.c_customer_sk, 
           COALESCE(total_sales, 0) AS total_sales, 
           COALESCE(order_count, 0) AS order_count,
           CASE 
               WHEN COALESCE(total_sales, 0) > 1000 THEN 'High Value'
               WHEN COALESCE(total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM customer_data
    LEFT JOIN sales_data ON customer_data.c_customer_sk = sales_data.ws_customer_sk
),
ranked_customers AS (
    SELECT c.*, 
           RANK() OVER (PARTITION BY c.customer_value ORDER BY c.total_sales DESC) AS sales_rank
    FROM average_sales AS c
)
SELECT ic.income_range, 
       COUNT(*) AS num_customers, 
       SUM(CASE WHEN rc.sales_rank <= 5 THEN 1 ELSE 0 END) AS top_customers_count,
       AVG(rc.total_sales) AS avg_sales
FROM ranked_customers AS rc
JOIN income_brackets AS ic ON rc.hd_income_band_sk = ic.ib_income_band_sk
WHERE rc.total_sales IS NOT NULL
GROUP BY ic.income_range
ORDER BY ic.ib_lower_bound;
