
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city != ah.ca_city
), RankedSales AS (
    SELECT ws_item_sk, 
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS sales_rank,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_profit) AS net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 30000 AND 40000 
    GROUP BY ws_item_sk
), CorrelatedReturns AS (
    SELECT sr_item_sk, 
           COUNT(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk
), Summary AS (
    SELECT i.i_item_sk, 
           i.i_item_desc,
           ah.ca_city,
           ah.ca_state,
           (COALESCE(s.total_quantity, 0) - COALESCE(r.total_returns, 0)) AS adjusted_sales,
           (COALESCE(s.net_profit, 0) - COALESCE(r.total_return_amt, 0)) AS adjusted_profit
    FROM item i
    LEFT JOIN RankedSales s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN CorrelatedReturns r ON i.i_item_sk = r.sr_item_sk
    JOIN AddressHierarchy ah ON EXISTS (SELECT 1 FROM customer_address ca WHERE ca.ca_address_sk = i.i_item_sk MOD 10)
    WHERE adjusted_sales > 1000
)
SELECT s.i_item_desc, 
       s.adjusted_sales,
       s.adjusted_profit,
       CASE 
           WHEN s.adjusted_sales > 5000 THEN 'High Seller'
           WHEN s.adjusted_sales BETWEEN 2000 AND 5000 THEN 'Medium Seller'
           ELSE 'Low Seller'
       END AS sales_category
FROM Summary s
ORDER BY s.adjusted_profit DESC, s.adjusted_sales ASC
LIMIT 50;
