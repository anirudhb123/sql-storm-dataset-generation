
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM web_sales
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM RankedSales
    WHERE SalesRank <= 5
    GROUP BY ws_item_sk
),
ItemCounts AS (
    SELECT 
        i_item_sk, 
        COUNT(DISTINCT ws_order_number) AS TotalSold,
        AVG(ws_ext_sales_price) AS AvgSalePrice
    FROM web_sales
    INNER JOIN item ON ws_item_sk = i_item_sk
    GROUP BY i_item_sk
),
HighPerformingItems AS (
    SELECT 
        ac.ws_item_sk,
        ac.TotalSales,
        ic.TotalSold,
        ic.AvgSalePrice
    FROM AggregateSales ac
    JOIN ItemCounts ic ON ac.ws_item_sk = ic.i_item_sk
    WHERE ac.TotalSales > (SELECT AVG(TotalSales) FROM AggregateSales)
)
SELECT 
    hi.ws_item_sk,
    hi.TotalSales,
    hi.TotalSold,
    hi.AvgSalePrice,
    ca.city,
    DATE_FORMAT(d.d_date, '%Y-%m') AS SalesMonth
FROM HighPerformingItems hi
LEFT JOIN item AS i ON hi.ws_item_sk = i.i_item_sk
LEFT JOIN customer_address AS ca ON i.i_item_sk = ca.ca_address_sk
CROSS JOIN date_dim d
WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 12
ORDER BY hi.TotalSales DESC, hi.AvgSalePrice DESC
LIMIT 10;
