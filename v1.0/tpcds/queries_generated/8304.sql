
WITH customer_info AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           cd.cd_purchase_estimate, hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT c.c_customer_id, SUM(ws.ws_ext_sales_price) AS total_sales, COUNT(ws.ws_order_number) AS total_orders
    FROM customer_info c
    JOIN web_sales ws ON c.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
average_sales AS (
    SELECT AVG(total_sales) AS avg_sales, AVG(total_orders) AS avg_orders
    FROM sales_summary
),
gender_sales AS (
    SELECT ci.cd_gender, SUM(ss.total_sales) AS gender_total_sales, COUNT(ss.total_orders) AS gender_order_count
    FROM sales_summary ss
    JOIN customer_info ci ON ss.c_customer_id = ci.c_customer_id
    GROUP BY ci.cd_gender
)
SELECT gs.cd_gender, gs.gender_total_sales, gs.gender_order_count, as.avg_sales, as.avg_orders
FROM gender_sales gs
CROSS JOIN average_sales as
WHERE gs.gender_total_sales > as.avg_sales OR gs.gender_order_count > as.avg_orders
ORDER BY gs.gender_total_sales DESC;
