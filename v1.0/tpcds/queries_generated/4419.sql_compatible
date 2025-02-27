
WITH filtered_sales AS (
    SELECT ws_item_sk, 
           ws_quantity, 
           ws_sales_price, 
           ws_ext_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
inventory_data AS (
    SELECT i_item_sk, 
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY i_item_sk
), 
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender,
           hd.hd_income_band_sk,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               ELSE 'Unmarried'
           END AS marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
sales_summary AS (
    SELECT ws_item_sk, 
           COUNT(*) AS total_orders, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales
    FROM filtered_sales
    GROUP BY ws_item_sk
)
SELECT ci.c_first_name, 
       ci.c_last_name, 
       ci.marital_status, 
       ci.cd_gender,
       ss.total_orders,
       ss.total_quantity,
       ss.total_sales,
       CASE 
           WHEN ss.total_sales IS NULL THEN 'No Sales'
           ELSE 'Sales Available'
       END AS sales_status,
       COALESCE(id.total_inventory, 0) AS inventory_status
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk 
LEFT JOIN inventory_data id ON ss.ws_item_sk = id.i_item_sk
WHERE ci.gender_rank <= 10
ORDER BY sales_status DESC, ss.total_sales DESC;
