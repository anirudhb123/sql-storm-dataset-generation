
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        EXTRACT(YEAR FROM d.d_date) AS sale_year,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sale_year,
        ws_item_sk,
        total_sales
    FROM SalesData
    WHERE sales_rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(cs.cs_ext_sales_price, 0) AS catalog_sales,
        COALESCE(ss.ss_ext_sales_price, 0) AS store_sales
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
)
SELECT 
    ts.sale_year,
    ts.ws_item_sk,
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    ts.total_sales,
    (id.catalog_sales + id.store_sales) AS total_catalog_store_sales,
    CASE 
        WHEN (id.catalog_sales + id.store_sales) IS NULL THEN 'No Sales'
        WHEN (id.catalog_sales + id.store_sales) > ts.total_sales THEN 'Higher Catalog/Store Sales'
        ELSE 'Lower Catalog/Store Sales'
    END AS sales_comparison
FROM TopSales ts
JOIN ItemDetails id ON ts.ws_item_sk = id.i_item_sk
ORDER BY ts.sale_year, total_sales DESC;
