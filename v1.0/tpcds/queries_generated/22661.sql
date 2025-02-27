
WITH RECURSIVE high_value_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 10000
),
customer_locations AS (
    SELECT c.c_customer_sk, 
           ca.ca_city, 
           ca.ca_state, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_country) AS location_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_sales,
           SUM(ws.ws_net_paid) AS total_revenue,
           AVG(ws.ws_sales_price) AS avg_price
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_item_sk
),
sales_stats AS (
    SELECT item.i_item_id,
           item.i_item_desc,
           i.total_sales,
           i.total_revenue,
           i.avg_price,
           CASE 
               WHEN i.total_sales > (SELECT AVG(total_sales) FROM item_sales) THEN 'Above Average' 
               ELSE 'Below Average' 
           END AS sales_performance
    FROM item item
    JOIN item_sales i ON item.i_item_sk = i.ws_item_sk
),
silver_customers AS (
    SELECT c.c_customer_sk,
           COUNT(ss.ss_ticket_number) AS store_purchases,
           SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ss.ss_net_paid) BETWEEN 5000 AND 10000
)
SELECT h.c_customer_sk,
       h.c_first_name,
       h.c_last_name,
       l.ca_city,
       l.ca_state,
       s.item_id,
       s.item_desc,
       s.sales_performance,
       f.total_spent
FROM high_value_customers h
LEFT JOIN customer_locations l ON h.c_customer_sk = l.c_customer_sk AND l.location_rank = 1
FULL OUTER JOIN sales_stats s ON 1 = CASE WHEN s.total_sales IS NOT NULL THEN 1 ELSE 0 END
LEFT JOIN silver_customers f ON h.c_customer_sk = f.c_customer_sk
WHERE (s.total_revenue IS NULL OR s.total_revenue > 10000)
  AND (h.rank <= 5 OR l.ca_state IS NULL)
ORDER BY h.c_customer_sk, s.total_sales DESC NULLS LAST
LIMIT 50 OFFSET (SELECT COUNT(*) FROM customer) / 2;
