
WITH product_sales AS (
    SELECT ws.ws_item_sk AS item_id,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           p.p_category AS product_category
    FROM web_sales ws
    JOIN item p ON ws.ws_item_sk = p.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01')
                                   AND (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31')
    GROUP BY ws.ws_item_sk, p.p_category
),
customer_info AS (
    SELECT c.c_customer_sk AS customer_id,
           cd.cd_gender AS gender,
           cd.cd_income_band_sk AS income_band,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01')
                                   AND (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31')
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
)
SELECT ci.gender,
       ib.ib_lower_bound AS income_range,
       SUM(ps.total_quantity_sold) AS total_units_sold,
       SUM(ps.total_sales) AS total_revenue,
       COUNT(DISTINCT ci.customer_id) AS unique_customers
FROM customer_info ci
JOIN income_band ib ON ci.income_band = ib.ib_income_band_sk
JOIN product_sales ps ON ci.total_orders > 0
GROUP BY ci.gender, ib.ib_lower_bound
ORDER BY total_revenue DESC;
