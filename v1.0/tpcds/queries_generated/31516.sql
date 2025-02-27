
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_ext_sales_price) AS TotalSales, COUNT(ws_order_number) AS SalesCount
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_ext_sales_price) AS TotalSales, COUNT(cs_order_number) AS SalesCount
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
),
SalesSummary AS (
    SELECT si.i_item_id, si.i_item_desc,
           COALESCE(SUM(s.TotalSales), 0) AS TotalSales,
           COALESCE(SUM(s.SalesCount), 0) AS SalesCount
    FROM item si
    LEFT JOIN SalesCTE s ON si.i_item_sk = s.ws_item_sk OR si.i_item_sk = s.cs_item_sk
    GROUP BY si.i_item_id, si.i_item_desc
),
TopSales AS (
    SELECT *, RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM SalesSummary
)
SELECT t.i_item_id, t.i_item_desc, t.TotalSales, t.SalesCount, 
       CONCAT('Item: ', t.i_item_desc, ' | Total Sales: ', t.TotalSales) AS SalesInfo, 
       CASE 
           WHEN t.TotalSales IS NULL THEN 'No Sales'
           WHEN t.TotalSales < 100 THEN 'Low Sales'
           WHEN t.TotalSales BETWEEN 100 AND 500 THEN 'Medium Sales'
           ELSE 'High Sales'
       END AS SalesCategory
FROM TopSales t
WHERE t.SalesRank <= 10
ORDER BY t.TotalSales DESC;
