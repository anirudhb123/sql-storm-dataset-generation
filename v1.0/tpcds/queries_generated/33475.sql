
WITH RECURSIVE PopularItems AS (
    SELECT i_item_sk, SUM(ws_quantity) AS total_quantity
    FROM item
    JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY i_item_sk
    HAVING SUM(ws_quantity) > 100
    UNION ALL
    SELECT i_item_sk, total_quantity
    FROM PopularItems
    WHERE total_quantity < 500
), ItemSales AS (
    SELECT ws_item_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           AVG(ws_ext_list_price) AS avg_list_price,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
), DailySales AS (
    SELECT d.d_date, SUM(ws_ext_sales_price) AS daily_sales
    FROM web_sales
    JOIN date_dim d ON web_sales.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
), TotalSales AS (
    SELECT SUM(daily_sales) AS full_year_sales
    FROM DailySales
), RankedSales AS (
    SELECT i.item_desc, sales.total_sales, sales.avg_list_price, ROW_NUMBER() OVER (ORDER BY sales.total_sales DESC) as rank
    FROM ItemSales sales
    JOIN item i ON sales.ws_item_sk = i.i_item_sk
)
SELECT r.item_desc, r.total_sales, r.avg_list_price, COALESCE(p.total_quantity, 0) as popular_quantity,
       (SELECT full_year_sales FROM TotalSales) AS full_year_sales
FROM RankedSales r
LEFT JOIN PopularItems p ON r.ws_item_sk = p.i_item_sk
WHERE r.rank <= 10
ORDER BY r.total_sales DESC;
