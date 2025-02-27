
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        COALESCE(NULLIF(ws.ws_coupon_amt, 0), 0) AS CouponAmount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_dow IN (1, 2, 3, 4, 5) AND d.d_holiday IS NULL
    )
), AggregatedSales AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_quantity) AS TotalQuantity,
        SUM(sd.ws_sales_price) AS TotalSales,
        SUM(sd.ws_ext_sales_price) AS TotalSalesWithTax,
        AVG(sd.CouponAmount) AS AverageCouponAmount,
        COUNT(DISTINCT sd.ws_sold_date_sk) AS DaysSold
    FROM SalesData sd
    JOIN item item ON sd.ws_item_sk = item.i_item_sk
    WHERE sd.SalesRank <= 5
    GROUP BY item.i_item_id
    HAVING SUM(sd.ws_quantity) > 100 AND AVG(sd.ws_sales_price) > 10.00
), RankSales AS (
    SELECT 
        item_id,
        TotalQuantity,
        TotalSales,
        TotalSalesWithTax,
        AverageCouponAmount,
        DaysSold,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM AggregatedSales
)
SELECT 
    r.item_id,
    r.TotalQuantity,
    r.TotalSales,
    r.TotalSalesWithTax,
    r.AverageCouponAmount,
    r.DaysSold,
    CASE 
        WHEN r.SalesRank IS NULL THEN 'Not Ranked' 
        ELSE CAST(r.SalesRank AS VARCHAR)
    END AS SalesRanking,
    CASE 
        WHEN r.TotalQuantity IS NULL THEN 'No Sales' 
        ELSE NULL
    END AS SalesStatus,
    COALESCE(MAX(s.cd_gender), 'Gender Unknown') AS ItemGender
FROM RankSales r
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk IN (
    SELECT DISTINCT c.c_current_cdemo_sk
    FROM customer c 
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    WHERE ss.ss_item_sk IN (SELECT ws_item_sk FROM SalesData WHERE ws_sales_price > 15)
)
GROUP BY r.item_id, r.TotalQuantity, r.TotalSales, r.TotalSalesWithTax, r.AverageCouponAmount, r.DaysSold, r.SalesRank
ORDER BY r.TotalSales DESC, r.TotalQuantity ASC;
