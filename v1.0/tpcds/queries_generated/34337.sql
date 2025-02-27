
WITH RECURSIVE sales_cte AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as row_num
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_ranking AS (
    SELECT c_customer_sk, c_first_name, c_last_name,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) as rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
avg_sales AS (
    SELECT ws_item_sk, AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT ca_state, 
       COUNT(DISTINCT customer_ranking.c_customer_sk) AS customer_count,
       SUM(sales_cte.ws_quantity) AS total_quantity,
       SUM(sales_cte.ws_net_paid) AS total_net_sales,
       COALESCE(avg_sales.avg_net_paid, 0) AS avg_net_sales_per_item
FROM customer_address
LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
LEFT JOIN sales_cte ON customer.c_customer_sk = sales_cte.ws_item_sk
LEFT JOIN customer_ranking ON customer.c_customer_sk = customer_ranking.c_customer_sk
LEFT JOIN avg_sales ON sales_cte.ws_item_sk = avg_sales.ws_item_sk
WHERE (ca_state IS NOT NULL OR ca_state <> '') AND
      (customer_ranking.rank <= 10 OR customer_ranking.rank IS NULL)
GROUP BY ca_state
ORDER BY total_net_sales DESC
LIMIT 100;
