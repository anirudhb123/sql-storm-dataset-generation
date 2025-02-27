
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT cr_item_sk,
           SUM(cr_return_quantity) AS total_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cr_item_sk
),
AggregatedSales AS (
    SELECT s.ws_item_sk,
           COALESCE(c.total_sales, 0) AS total_sales,
           COALESCE(r.total_returns, 0) AS total_returns,
           COALESCE(c.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_sales
    FROM SalesCTE s
    LEFT JOIN CustomerReturns r ON s.ws_item_sk = r.cr_item_sk
    LEFT JOIN (
        SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
        FROM web_sales
        GROUP BY ws_item_sk
    ) c ON s.ws_item_sk = c.ws_item_sk
    WHERE s.rn = 1
)
SELECT a.ws_item_sk,
       a.total_sales,
       a.total_returns,
       a.net_sales,
       CASE 
           WHEN a.net_sales < 0 THEN 'Returns Excessive'
           WHEN a.net_sales = 0 THEN 'Neutral'
           ELSE 'Positive Sales'
       END AS sales_status
FROM AggregatedSales a
ORDER BY a.net_sales DESC;
