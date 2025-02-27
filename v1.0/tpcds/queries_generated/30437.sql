
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, i_class, 1 AS level
    FROM item
    WHERE i_current_price > 100.00

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_brand, i.i_class, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
),
SalesSummary AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_net_paid,
           SUM(ws_ext_sales_price) AS total_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT sh.total_quantity,
           sh.total_net_paid,
           sh.total_sales_price,
           ih.i_item_desc,
           ih.i_brand,
           ih.i_class,
           ROW_NUMBER() OVER (PARTITION BY ih.i_class ORDER BY sh.total_sales_price DESC) AS sales_rank
    FROM SalesSummary sh
    JOIN ItemHierarchy ih ON sh.ws_item_sk = ih.i_item_sk
),
TopSales AS (
    SELECT *
    FROM FilteredSales
    WHERE sales_rank <= 10
)
SELECT ca.city, 
       ca.state, 
       COUNT(ts.total_sales_price) AS top_sales_count,
       SUM(ts.total_sales_price) AS total_sales_value,
       AVG(ts.total_net_paid) AS average_net_paid
FROM TopSales ts
JOIN customer c ON ts.ws_item_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.city, ca.state
HAVING SUM(ts.total_sales_price) > 1000
ORDER BY total_sales_value DESC;
