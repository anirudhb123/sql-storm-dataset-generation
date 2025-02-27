
WITH RECURSIVE TotalReturns AS (
    SELECT sr_item_sk, 
           COUNT(*) AS total_returns, 
           SUM(sr_return_amt) AS total_return_amount,
           ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM store_returns 
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - INTERVAL '1 year'
    GROUP BY sr_item_sk
),
RecentSales AS (
    SELECT ws_item_sk, 
           COUNT(*) AS total_sales, 
           SUM(ws_sales_price) AS total_sales_amount,
           SUM(ws_quantity) AS total_quantity_sold,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - INTERVAL '1 year'
    GROUP BY ws_item_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        COALESCE(tr.total_returns, 0) AS total_returns,
        COALESCE(rs.total_sales, 0) AS total_sales,
        (CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 0 
            ELSE (COALESCE(tr.total_returns, 0)::decimal / COALESCE(rs.total_sales, 0)) 
         END) AS return_rate,
         (CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 0 
            ELSE (COALESCE(rs.total_sales_amount, 0) / COALESCE(rs.total_sales, 0)) 
         END) AS average_sales_price
    FROM item i
    LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
    LEFT JOIN RecentSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE i.i_current_price IS NOT NULL
)
SELECT p.i_item_id, 
       p.total_returns,
       p.total_sales,
       p.return_rate,
       p.average_sales_price,
       ROW_NUMBER() OVER (ORDER BY p.return_rate DESC) as popularity_rank
FROM PopularItems p
WHERE p.return_rate > 0.1
ORDER BY popularity_rank
LIMIT 10;
