
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_category, i_current_price, 0 AS level
    FROM item
    WHERE i_item_sk = (SELECT MIN(i_item_sk) FROM item)  -- Start from the lowest item
    UNION ALL
    SELECT i.item_sk, i.i_item_desc, i.i_brand, i.i_category, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.brand_id = ih.i_item_sk  -- Join to relate items by brand
), 
CustomerReturns AS (
    SELECT c.c_customer_sk, c.c_customer_id, SUM(sr_return_quantity) AS total_returned
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
RevenueSummary AS (
    SELECT ws.ws_sold_date_sk, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_sold_date_sk
), 
AvgReturns AS (
    SELECT AVG(total_returned) AS avg_returns FROM CustomerReturns
)
SELECT 
    d.d_date AS sale_date,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(a.avg_returns, 0) AS average_returns,
    ih.i_item_desc,
    MAX(ih.level) AS item_hierarchy_level,
    ROUND(AVG(ih.i_current_price), 2) AS avg_item_price
FROM date_dim d
LEFT JOIN RevenueSummary r ON d.d_date_sk = r.ws_sold_date_sk
CROSS JOIN AvgReturns a
LEFT JOIN ItemHierarchy ih ON ih.i_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand IN ('BrandA', 'BrandB'))
WHERE d.d_year = 2023
GROUP BY d.d_date, r.total_sales, a.avg_returns, ih.i_item_desc
ORDER BY sale_date, item_hierarchy_level DESC;
