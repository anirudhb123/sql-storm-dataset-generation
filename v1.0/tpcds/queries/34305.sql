WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_data AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 2459600 
    GROUP BY ws.ws_item_sk
),
returns_data AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_quantity) AS total_returns,
           SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
combined_sales AS (
    SELECT sd.ws_item_sk,
           sd.total_quantity,
           sd.total_sales,
           rd.total_returns,
           rd.return_amount,
           (sd.total_sales - COALESCE(rd.return_amount, 0)) AS net_sales,
           ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
    LEFT JOIN returns_data rd ON sd.ws_item_sk = rd.cr_item_sk
)
SELECT ch.c_first_name,
       ch.c_last_name,
       cs.ws_item_sk,
       cs.net_sales,
       RANK() OVER (PARTITION BY ch.c_current_cdemo_sk ORDER BY cs.net_sales DESC) AS customer_sales_rank
FROM customer_hierarchy ch
JOIN combined_sales cs ON ch.c_current_cdemo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_demo_sk = ch.c_current_cdemo_sk)
WHERE cs.net_sales IS NOT NULL
AND ch.level < 3
ORDER BY ch.c_current_cdemo_sk, customer_sales_rank;