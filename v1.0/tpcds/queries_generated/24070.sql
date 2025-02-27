
WITH RECURSIVE warehouse_hierarchy AS (
    SELECT w_warehouse_sk, w_warehouse_id, w_street_name, w_city, w_state, w_country, 
           ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY w_warehouse_sk) AS rank 
    FROM warehouse
    WHERE w_country IS NOT NULL AND w_state IS NOT NULL
),
customer_details AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_education_status, 
           (CASE 
                WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'S' THEN 'Single Male'
                WHEN cd.cd_gender = 'M' AND cd_marital_status = 'M' THEN 'Married Male'
                WHEN cd.cd_gender = 'F' AND cd_marital_status = 'S' THEN 'Single Female'
                ELSE 'Married Female'
            END) AS gender_marital,
           COALESCE(cd.cd_dep_count, 0) AS dependent_count
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales, 
           SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
           (SUM(ws.ws_net_paid_inc_tax) - SUM(ws.ws_ext_wholesale_cost)) AS total_profit
    FROM web_sales ws 
    GROUP BY ws.ws_item_sk
),
item_information AS (
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price, 
           CASE 
               WHEN i.i_current_price IS NULL THEN 'Price Not Set' 
               ELSE 'Price Set' 
           END AS price_status
    FROM item i 
    WHERE i.i_rec_end_date IS NULL
),
return_stats AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returns,
           COUNT(DISTINCT sr_ticket_number) AS unique_return_tickets,
           CASE 
               WHEN SUM(sr_return_quantity) > 0 THEN 'Returned Items Exist'
               ELSE 'No Returns'
           END AS return_status
    FROM store_returns 
    GROUP BY sr_item_sk
)
SELECT wd.warehouse_id, 
       wd.warehouse_name,
       cd.gender_marital,
       COUNT(DISTINCT c.c_customer_sk) AS total_customers, 
       SUM(sd.total_sales) AS total_sales_quantity, 
       SUM(sd.total_revenue) AS total_revenue_amount, 
       COALESCE(SUM(rs.total_returns), 0) AS total_return_quantity,
       COALESCE(SUM(rs.unique_return_tickets), 0) AS total_unique_return_tickets,
       ROW_NUMBER() OVER (PARTITION BY wd.warehouse_id ORDER BY SUM(sd.total_revenue) DESC) AS revenue_rank
FROM warehouse_hierarchy wd
LEFT JOIN customer_details cd ON cd.c_customer_sk = wd.warehouse_sk
LEFT JOIN sales_data sd ON sd.ws_item_sk = (SELECT MIN(i_item_sk) FROM item_information)
LEFT JOIN return_stats rs ON rs.sr_item_sk = (SELECT MAX(sr_item_sk) FROM store_returns)
WHERE wd.rank <= 5
GROUP BY wd.warehouse_id, wd.warehouse_name, cd.gender_marital
ORDER BY total_revenue_amount DESC, total_customers ASC;
