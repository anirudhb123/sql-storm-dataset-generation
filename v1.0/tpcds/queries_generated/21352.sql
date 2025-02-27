
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as SalesRank
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS TotalQuantity,
        SUM(rs.ws_sales_price) AS TotalSales,
        AVG(rs.ws_sales_price) AS AveragePrice,
        MIN(rs.ws_sales_price) AS MinPrice,
        MAX(rs.ws_sales_price) AS MaxPrice
    FROM RankedSales rs
    WHERE rs.SalesRank <= 3
    GROUP BY rs.ws_item_sk
),
TopItems AS (
    SELECT 
        s.ws_item_sk,
        ss.TotalQuantity,
        ss.TotalSales,
        ss.AveragePrice,
        ss.MinPrice,
        ss.MaxPrice,
        COALESCE(i.i_item_desc, 'Description Not Available') AS ItemDescription,
        COALESCE(sm.sm_type, 'Unknown Shipping Method') AS ShippingMethod
    FROM SalesSummary ss
    LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON ss.ws_item_sk IN (
        SELECT sr_item_sk 
        FROM store_returns 
        WHERE sr_return_quantity > 0
    )
),
FinalReport AS (
    SELECT 
        ti.ItemDescription,
        ti.ShippingMethod,
        ti.TotalQuantity,
        ti.TotalSales,
        ti.AveragePrice,
        CASE 
            WHEN ti.MaxPrice IS NULL THEN 'No Transactions'
            WHEN ti.MaxPrice > 100 THEN 'High Value Item'
            ELSE 'Standard Item'
        END AS ValueCategory
    FROM TopItems ti
    WHERE ti.TotalSales IS NOT NULL 
      AND ti.TotalSales >= (SELECT AVG(TotalSales) FROM SalesSummary)
)
SELECT 
    fr.ItemDescription,
    fr.TotalQuantity,
    fr.TotalSales,
    fr.AveragePrice,
    fr.ShippingMethod,
    fr.ValueCategory
FROM FinalReport fr
ORDER BY fr.TotalSales DESC
LIMIT 10;
