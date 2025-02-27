
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        COALESCE(SUM(store_sales.ss_quantity), 0) AS total_store_quantity,
        COALESCE(SUM(store_sales.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ss_store_sk) AS store_count,
        COUNT(DISTINCT ws_bill_customer_sk) AS web_sales_customers
    FROM item
    LEFT JOIN store_sales ON item.i_item_sk = store_sales.ss_item_sk
    LEFT JOIN SalesCTE ON item.i_item_sk = SalesCTE.ws_item_sk
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY item.i_item_sk, item.i_item_id, item.i_item_desc, item.i_current_price
),
FilteredResults AS (
    SELECT *,
        ROUND(total_store_sales / NULLIF(total_store_quantity, 0), 2) AS avg_store_sales_per_item,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM (
        SELECT 
            i_item_id,
            i_item_desc,
            i_current_price,
            total_store_quantity,
            total_store_sales,
            store_count,
            web_sales_customers
        FROM TopSales
        WHERE total_store_sales > 0
    ) AS Ranked
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.i_current_price,
    f.total_store_quantity,
    f.total_store_sales,
    f.store_count,
    f.web_sales_customers,
    f.avg_store_sales_per_item,
    CASE 
        WHEN f.sales_rank <= 10 THEN 'Top 10'
        WHEN f.sales_rank > 10 AND f.sales_rank <= 20 THEN 'Top 20'
        ELSE 'Other'
    END AS sales_category
FROM FilteredResults f 
WHERE f.web_sales_customers > 0
ORDER BY f.total_store_sales DESC;
