
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           level + 1
    FROM customer AS ch
    JOIN customer_hierarchy AS ch_parent ON ch.c_current_cdemo_sk = ch_parent.c_current_cdemo_sk
    WHERE ch.c_customer_sk != ch_parent.c_customer_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
gender_demos AS (
    SELECT cd_gender, COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender
),
warehouse_inventory AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_warehouse_sk
),
outer_sales AS (
    SELECT s_store_sk, COALESCE(SUM(ss_ext_sales_price), 0) AS store_sales
    FROM store_sales
    GROUP BY s_store_sk
    HAVING SUM(ss_ext_sales_price) > 1000
),
final_result AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ss.net_profit) AS total_net_profit,
           wd.total_inventory,
           gd.customer_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY total_net_profit DESC) AS profit_rank
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN warehouse_inventory AS wd ON wd.inv_warehouse_sk = ss.ss_store_sk
    JOIN gender_demos AS gd ON gd.customer_count > 10
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, wd.total_inventory, gd.customer_count
)
SELECT f.c_customer_sk, f.c_first_name, f.c_last_name, f.total_net_profit, 
       f.total_inventory, f.customer_count, COALESCE(oh.store_sales, 0) AS outer_sales
FROM final_result AS f
LEFT JOIN outer_sales AS oh ON f.c_customer_sk = oh.s_store_sk
WHERE f.profit_rank <= 5
ORDER BY f.total_net_profit DESC, f.customer_count ASC;
