
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_sales_price, ws_quantity, 
           ws_net_paid, 1 AS depth
    FROM web_sales
    WHERE ws_sold_date_sk >= 2451545 -- Arbitrarily chosen date
    UNION ALL
    SELECT cs_sold_date_sk, cs_item_sk, cs_sales_price, cs_quantity, 
           cs_net_paid, depth + 1
    FROM catalog_sales
    JOIN SalesCTE ON SalesCTE.ws_item_sk = catalog_sales.cs_item_sk
    WHERE catalog_sales.cs_sold_date_sk >= 2451545
),
TotalSales AS (
    SELECT 
        item.i_item_id,
        SUM(CASE WHEN ws_sales_price IS NOT NULL THEN ws_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs_sales_price IS NOT NULL THEN cs_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(ws_quantity + cs_quantity) AS total_quantity,
        COUNT(DISTINCT ws_item_sk) OVER (PARTITION BY item.i_item_id) AS web_sales_count,
        COUNT(DISTINCT cs_item_sk) OVER (PARTITION BY item.i_item_id) AS catalog_sales_count,
        ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    LEFT JOIN catalog_sales ON item.i_item_sk = catalog_sales.cs_item_sk
    GROUP BY item.i_item_id
)
SELECT 
    ta.i_item_id,
    ta.total_web_sales,
    ta.total_catalog_sales,
    ta.total_quantity,
    ta.web_sales_count,
    ta.catalog_sales_count
FROM TotalSales ta
WHERE (ta.web_sales_count + ta.catalog_sales_count) > 0
AND ta.total_web_sales > (SELECT AVG(total_web_sales) FROM TotalSales)
ORDER BY ta.total_quantity DESC
LIMIT 10;
