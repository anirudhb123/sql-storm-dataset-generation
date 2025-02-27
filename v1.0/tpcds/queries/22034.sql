
WITH RECURSIVE customer_paths AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           ca.ca_city, 
           ca.ca_state,
           1 AS level
    FROM customer c 
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL
    
    UNION ALL
    
    SELECT cp.c_customer_sk, 
           cp.c_customer_id, 
           cp.c_first_name, 
           cp.c_last_name, 
           ca.ca_city, 
           ca.ca_state,
           cp.level + 1
    FROM customer_paths cp
    JOIN customer c ON cp.c_customer_id = c.c_customer_id 
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cp.level < 5
),

sales_data AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY ws.ws_item_sk
),

top_items AS (
    SELECT i.i_item_id, 
           i.i_item_desc, 
           sd.total_quantity,
           sd.total_net_paid,
           ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sd.total_net_paid DESC) AS rnk
    FROM item i
    JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    WHERE i.i_current_price > 0
),

null_handling AS (
    SELECT t.*, 
           COALESCE(t.total_net_paid, 0) AS adjusted_net_paid
    FROM top_items t
    WHERE t.rnk <= 10 OR t.total_quantity IS NULL
)

SELECT cp.c_customer_id, 
       cp.c_first_name, 
       cp.c_last_name, 
       nh.i_item_id,
       nh.i_item_desc,
       nh.adjusted_net_paid,
       CASE 
           WHEN nh.adjusted_net_paid = 0 THEN 'No sales' 
           WHEN nh.adjusted_net_paid < 100 THEN 'Low sales' 
           ELSE 'High sales'
       END AS sales_category
FROM customer_paths cp
LEFT JOIN null_handling nh ON cp.c_customer_sk = (SELECT c.c_customer_sk 
                                                  FROM customer c 
                                                  WHERE c.c_customer_id = cp.c_customer_id 
                                                  LIMIT 1)
ORDER BY cp.c_last_name ASC, cp.c_first_name ASC;
