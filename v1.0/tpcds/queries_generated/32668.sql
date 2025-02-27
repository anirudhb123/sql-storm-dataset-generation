
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           d.cd_gender, d.cd_marital_status, d.cd_purchase_estimate,
           0 AS depth
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_gender = 'F'
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           d.cd_gender, d.cd_marital_status, d.cd_purchase_estimate,
           ch.depth + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_marital_status = 'M'
),
ItemSummary AS (
    SELECT i.i_item_sk, i.i_product_name, SUM(ws.ws_sales_price) AS total_sales, 
           COUNT(ws.ws_order_number) AS total_orders
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
),
AddressAndSales AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state,
           SUM(ss.ss_net_paid) AS total_store_sales,
           COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM customer_address ca
    LEFT JOIN store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_purchase_estimate,
       is.i_product_name, is.total_sales, is.total_orders,
       as.ca_city, as.ca_state, as.total_store_sales, as.store_sales_count
FROM CustomerHierarchy ch
LEFT JOIN ItemSummary is ON ch.c_customer_sk = is.i_item_sk
LEFT JOIN AddressAndSales as ON ch.c_customer_sk = as.ca_address_sk
WHERE (is.total_orders > 10 OR as.total_store_sales > 1000)
  AND ch.depth <= 2
ORDER BY total_sales DESC, ch.c_last_name, ch.c_first_name;
