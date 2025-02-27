
WITH RECURSIVE sales_summary AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, 
           SUM(cs_quantity) AS total_quantity, 
           SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales 
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
),
customer_statistics AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING COUNT(ws.ws_order_number) > 10
),
item_rankings AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM item i
    INNER JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
overall_metrics AS (
    SELECT SUM(total_sales) AS grand_total_sales,
           SUM(total_quantity) AS grand_total_quantity
    FROM (
        SELECT total_sales, total_quantity FROM sales_summary
    ) AS sales_data
)
SELECT cs.full_name, 
       cs.cd_gender, 
       cs.cd_marital_status, 
       ir.i_item_id, 
       ir.sales_rank,
       cm.grand_total_sales,
       cm.grand_total_quantity
FROM customer_statistics cs
JOIN item_rankings ir ON cs.total_profit > 1000 AND ir.sales_rank <= 10
CROSS JOIN overall_metrics cm
WHERE cs.cd_gender = 'F' 
  AND cs.cd_marital_status IS NOT NULL
  AND ir.i_item_id LIKE '%A%'
ORDER BY cm.grand_total_sales DESC, cs.total_orders DESC;
