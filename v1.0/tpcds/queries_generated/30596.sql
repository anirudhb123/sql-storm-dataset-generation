
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_rec_start_date, i_rec_end_date,
           1 AS level
    FROM item
    WHERE i_rec_start_date IS NOT NULL
    UNION ALL
    SELECT i.item_sk, i.item_id, ih.i_product_name, i.i_rec_start_date, i.i_rec_end_date,
           ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE i.i_rec_start_date > ih.i_rec_start_date
),
SalesData AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CombinedSales AS (
    SELECT sd.ws_item_sk, SUM(sd.total_sales) AS overall_sales, COUNT(sd.ws_sold_date_sk) AS sale_days
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_product_name, 
    COALESCE(cs.overall_sales, 0) AS total_web_sales,
    COALESCE(NULLIF(cs.sale_days, 0), NULL) AS unique_sale_days,
    CASE 
        WHEN ih.level IS NOT NULL THEN 'Hierarchical'
        ELSE 'Flat'
    END AS item_category,
    SUM(CASE WHEN cs.total_sales IS NOT NULL THEN cs.total_sales ELSE 0 END) OVER (PARTITION BY i.i_item_sk ORDER BY total_web_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_sales
FROM item i
LEFT JOIN CombinedSales cs ON i.i_item_sk = cs.ws_item_sk
LEFT JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
AND i.i_rec_end_date IS NULL 
AND EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk BETWEEN 2400 AND 2500
);
