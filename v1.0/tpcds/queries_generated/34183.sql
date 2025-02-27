
WITH RECURSIVE item_sales AS (
    SELECT l.item_sk, l.order_number, l.sales_price, l.quantity, 
           SUM(l.sales_price * l.quantity) OVER (PARTITION BY l.item_sk ORDER BY l.order_number) AS cumulative_sales,
           ROW_NUMBER() OVER (PARTITION BY l.item_sk ORDER BY l.order_number) AS sales_rank
    FROM (
        SELECT ws.ws_item_sk AS item_sk, ws.ws_order_number AS order_number,
               (ws.ws_sales_price - ws.ws_ext_discount_amt) AS sales_price,
               ws.ws_quantity AS quantity
        FROM web_sales ws
        UNION ALL
        SELECT cs.cs_item_sk AS item_sk, cs.cs_order_number AS order_number,
               (cs.cs_sales_price - cs.cs_ext_discount_amt) AS sales_price,
               cs.cs_quantity AS quantity
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_item_sk AS item_sk, ss.ss_ticket_number AS order_number,
               (ss.ss_sales_price - ss.ss_ext_discount_amt) AS sales_price,
               ss.ss_quantity AS quantity
        FROM store_sales ss
    ) l
),
customer_stats AS (
    SELECT DISTINCT c.c_customer_id, 
           SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit,
           COUNT(DISTINCT l.order_number) AS total_orders,
           MAX(l.cumulative_sales) AS max_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN item_sales l ON l.item_sk = ss.ss_item_sk OR l.item_sk = ws.ws_item_sk OR l.item_sk = cs.cs_item_sk
    GROUP BY c.c_customer_id
),
address_info AS (
    SELECT ca.ca_address_id, 
           ca.ca_city || ', ' || ca.ca_state AS full_address,
           COUNT(DISTINCT c.c_customer_sk) AS customers_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT cs.c_customer_id, cs.total_net_profit, cs.total_orders, cs.max_sales, 
       ai.full_address, ai.customers_count
FROM customer_stats cs
LEFT JOIN address_info ai ON cs.c_customer_id = ai.customers_count
WHERE cs.total_net_profit > 0
  AND cs.max_sales > 100
  AND EXISTS (
      SELECT 1 
      FROM date_dim d 
      WHERE d.d_year = 2023 
        AND d.d_date_id = CAST(20230101 AS CHAR)
  )
ORDER BY cs.total_net_profit DESC
FETCH FIRST 100 ROWS ONLY;
