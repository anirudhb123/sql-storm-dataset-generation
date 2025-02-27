
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_current_price, 0 AS level
    FROM item
    WHERE i_brand = 'BrandA'
    UNION ALL
    SELECT i.item_sk, i.i_item_desc, i.i_brand, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_brand = ih.i_brand
    WHERE i.i_item_sk <> ih.i_item_sk
),
SalesData AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450810 AND 2450850
    GROUP BY ws.ws_item_sk
),
ItemSales AS (
    SELECT ih.i_item_sk, 
           ih.i_item_desc, 
           ih.i_brand, 
           ih.i_current_price, 
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.total_orders, 0) AS total_orders
    FROM ItemHierarchy ih
    LEFT JOIN SalesData sd ON ih.i_item_sk = sd.ws_item_sk
)
SELECT i.i_item_desc, 
       i.i_brand, 
       i.i_current_price, 
       i.total_sales, 
       i.total_orders,
       RANK() OVER (ORDER BY i.total_sales DESC) AS sales_rank,
       CASE 
           WHEN i.total_sales > 10000 THEN 'High Seller'
           WHEN i.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Seller'
           ELSE 'Low Seller'
       END AS sales_category
FROM ItemSales i
WHERE i.total_orders > 0
ORDER BY i.total_sales DESC;
