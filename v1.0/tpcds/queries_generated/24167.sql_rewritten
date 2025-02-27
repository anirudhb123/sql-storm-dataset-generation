WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_current_price, 
           0 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_current_price, 
           h.level + 1
    FROM ItemHierarchy h
    JOIN item ih ON ih.i_item_sk = h.i_item_sk AND ih.i_current_price < h.i_current_price
),
TopItems AS (
    SELECT i_item_id, SUM(i_current_price) AS total_price
    FROM ItemHierarchy
    GROUP BY i_item_id
    ORDER BY total_price DESC
    LIMIT 10
),
SalesData AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT sd.ws_item_sk, 
           sd.total_quantity, 
           sd.total_sales,
           COALESCE(sh.sm_type, 'Unknown') AS ship_mode,
           ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS rn
    FROM SalesData sd
    LEFT JOIN ship_mode sh ON sh.sm_ship_mode_sk = sd.ws_item_sk % 10
)
SELECT c.c_first_name, 
       c.c_last_name,
       a.ca_city,
       t.total_price,
       s.total_quantity,
       s.total_sales,
       s.ship_mode
FROM customer c
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN TopItems t ON t.i_item_id = c.c_customer_id
JOIN TopSales s ON s.ws_item_sk = c.c_customer_sk
WHERE a.ca_city IS NOT NULL 
  AND (c.c_birth_month = (EXTRACT(MONTH FROM cast('2002-10-01' as date)) - 1) OR c.c_birth_month IS NULL)
  AND s.rn <= 3
ORDER BY a.ca_city, s.total_sales DESC
FETCH FIRST 10 ROWS ONLY;