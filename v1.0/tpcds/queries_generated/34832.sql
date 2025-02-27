
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, c.level + 1
    FROM customer_address a
    JOIN address_cte c ON a.ca_address_sk = c.ca_address_sk
    WHERE c.level < 3
),
customer_stats AS (
    SELECT c.c_customer_sk, 
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           MAX(cd.cd_dep_count) AS max_dependents,
           AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
sales_summary AS (
    SELECT ss.ss_item_sk,
           SUM(ss.ss_ext_sales_price) AS total_store_sales,
           AVG(ss.ss_net_profit) AS avg_net_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ss.ss_item_sk
),
combined_sales AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM catalog_sales cs
    JOIN customer_stats cs2 ON cs2.total_sales > 1000
    GROUP BY cs.cs_item_sk
)
SELECT a.ca_city, 
       a.ca_state, 
       a.ca_country,
       COALESCE(cs.total_sales, 0) AS customer_total_sales,
       COALESCE(su.total_store_sales, 0) AS store_sales,
       COALESCE(com.total_catalog_sales, 0) AS catalog_sales
FROM address_cte a
LEFT JOIN customer_stats cs ON cs.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk)
LEFT JOIN sales_summary su ON su.ss_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_brand_id IN (1, 2))
LEFT JOIN combined_sales com ON com.cs_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_size LIKE 'M%')
ORDER BY a.ca_state, customer_total_sales DESC
LIMIT 100;
