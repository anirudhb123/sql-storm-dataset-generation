
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i.item_sk, i.item_desc, i.brand, i.current_price, 
           1 AS level
    FROM item i
    WHERE i.rec_start_date <= CURRENT_DATE AND 
          (i.rec_end_date IS NULL OR i.rec_end_date > CURRENT_DATE)
    
    UNION ALL
    
    SELECT c.item_sk, c.item_desc, c.brand, c.current_price * 0.9 AS discounted_price,
           ch.level + 1
    FROM CategoryHierarchy ch
    JOIN item c ON ch.item_sk = c.item_sk AND ch.level < 5
)
SELECT ca_city,
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       MAX(ws.ws_net_paid) AS max_net_paid,
       STRING_AGG(DISTINCT i.i_product_name, ', ') AS featured_products
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN CategoryHierarchy i ON ws.ws_item_sk = i.item_sk
WHERE ca.ca_state = 'CA' AND 
      i.current_price > 20
GROUP BY ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 50 OR 
       SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 10;
