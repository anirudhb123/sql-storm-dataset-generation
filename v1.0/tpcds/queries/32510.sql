
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           NULL AS parent_customer_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ch.c_customer_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),

sales_summary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS orders_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),

address_count AS (
    SELECT ca_county,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_county
),

detailed_sales AS (
    SELECT cs_item_sk,
           SUM(cs_quantity) AS total_quantity,
           SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY cs_item_sk
)

SELECT ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
       ss.total_sales,
       ss.orders_count,
       ac.ca_county,
       COALESCE(ds.total_quantity, 0) AS total_quantity,
       COALESCE(ds.total_profit, 0) AS total_profit
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.customer_sk
LEFT JOIN address_count ac ON ch.c_customer_sk = ac.customer_count
LEFT JOIN detailed_sales ds ON ch.c_customer_sk = ds.cs_item_sk
WHERE ch.level = 0
ORDER BY ss.total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
