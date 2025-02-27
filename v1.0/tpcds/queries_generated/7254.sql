
WITH customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_education_status, cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales, 
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
date_data AS (
    SELECT d.d_date_sk, d.d_date, d.d_month_seq, d.d_year
    FROM date_dim d
),
promotions_data AS (
    SELECT p.p_promo_sk, p.p_promo_name, COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT cd.c_first_name, cd.c_last_name, cd.cd_gender, sd.total_sales, sd.total_quantity, 
       dd.d_date, dd.d_month_seq, dd.d_year, pd.promo_sales_count
FROM customer_data cd
JOIN sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
JOIN date_data dd ON sd.ws_sold_date_sk = dd.d_date_sk
LEFT JOIN promotions_data pd ON sd.ws_item_sk IN (
    SELECT p.p_item_sk 
    FROM promotion p
    WHERE p.p_start_date_sk <= dd.d_date_sk AND p.p_end_date_sk >= dd.d_date_sk
)
WHERE cd.cd_purchase_estimate > 1000
ORDER BY sd.total_sales DESC, dd.d_year DESC;
