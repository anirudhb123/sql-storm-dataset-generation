
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales 
    GROUP BY ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(si.sales_in_last_month, 0) AS sales_in_last_month
    FROM item i
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_quantity) AS sales_in_last_month
        FROM web_sales
        WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date >= CURRENT_DATE - INTERVAL '1 month')
        GROUP BY ws_item_sk
    ) si ON i.i_item_sk = si.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        s.total_quantity_sold,
        s.total_sales
    FROM ItemDetails id
    JOIN SalesCTE s ON id.i_item_sk = s.ws_item_sk
    WHERE s.sales_rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_product_name,
    tsi.total_quantity_sold,
    tsi.total_sales,
    CASE 
        WHEN tsi.total_sales > 10000 THEN 'High'
        WHEN tsi.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COALESCE(NULLIF(tsi.total_sales, 0), 'No Sales') AS sales_check
FROM TopSellingItems tsi
ORDER BY tsi.total_sales DESC;
