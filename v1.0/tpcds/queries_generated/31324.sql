
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, 
           SUM(cs_quantity) AS total_quantity,
           SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    GROUP BY cs_item_sk
),
Item_Sales AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
           COALESCE(SUM(s.total_sales), 0) AS total_sales_value,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(s.total_sales), 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN Sales_CTE s ON i.i_item_sk = s.ws_item_sk OR i.i_item_sk = s.cs_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT i.i_item_id,
       i.total_quantity_sold,
       i.total_sales_value,
       CASE 
           WHEN i.total_sales_value > 1000 THEN 'High Sales'
           WHEN i.total_sales_value BETWEEN 500 AND 1000 THEN 'Medium Sales'
           ELSE 'Low Sales'
       END AS sales_category
FROM Item_Sales i
WHERE i.total_quantity_sold > 0
AND (i.total_sales_value IS NOT NULL OR i.total_sales_value IS NOT NULL)
ORDER BY i.total_sales_value DESC
LIMIT 10;
