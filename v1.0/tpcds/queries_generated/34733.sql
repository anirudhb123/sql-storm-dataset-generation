
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_ext_sales_price, ws_order_number,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) as rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT ws_order_number) AS order_count,
           SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT sd.ws_item_sk, SUM(sd.ws_quantity) AS total_quantity, AVG(sd.ws_ext_sales_price) AS avg_price,
           max(sd.ws_ext_sales_price) as max_price, MIN(sd.ws_ext_sales_price) as min_price
    FROM sales_data sd
    GROUP BY sd.ws_item_sk
),
ranked_customers AS (
    SELECT cd.*, RANK() OVER (ORDER BY cd.total_spent DESC) AS customer_rank
    FROM customer_data cd
),
final_output AS (
    SELECT rc.c_first_name, rc.c_last_name, rc.order_count, rc.total_spent,
           ss.total_quantity, ss.avg_price, ss.max_price, ss.min_price
    FROM ranked_customers rc
    JOIN sales_summary ss ON rc.order_count > 5 AND ss.total_quantity > 0
)
SELECT *
FROM final_output
WHERE customer_rank <= 10
ORDER BY total_spent DESC;
