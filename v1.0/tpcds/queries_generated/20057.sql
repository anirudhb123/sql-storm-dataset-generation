
WITH RecursiveHierarchy AS (
    SELECT c_customer_sk, c_first_name || ' ' || c_last_name AS customer_name, NULL AS parent_sk
    FROM customer
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM store_sales WHERE ss_quantity > (SELECT AVG(ss_quantity) FROM store_sales))
    
    UNION ALL
    
    SELECT sr_customer_sk, wr_returned_date_sk::text || ' - ' || wr_item_sk::text AS customer_name, sr_customer_sk
    FROM web_returns
    WHERE wr_return_quantity > (SELECT MAX(sr_return_quantity) FROM store_returns)
), 

PriceCalculations AS (
    SELECT i_item_sk, i_item_desc, i_current_price,
           CASE 
               WHEN i_current_price IS NULL THEN 'Price Not Available'
               ELSE TO_CHAR(i_current_price * 1.15, '$9999.99')
           END AS adjusted_price,
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_item_sk) AS price_rank
    FROM item
), 

SalesAggregates AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_profit) AS total_net_profit,
           RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
)

SELECT rh.customer_name, pc.i_item_desc, pc.adjusted_price, sa.total_quantity, sa.total_net_profit
FROM RecursiveHierarchy rh
LEFT JOIN PriceCalculations pc ON rh.c_customer_sk = pc.i_item_sk
FULL OUTER JOIN SalesAggregates sa ON pc.i_item_sk = sa.ws_item_sk
WHERE (rh.c_customer_sk IS NOT NULL OR pc.i_item_sk IS NOT NULL)
AND (sa.total_quantity IS NOT NULL AND sa.total_net_profit > 100)
OR (rh.customer_name LIKE '%John%' AND pc.adjusted_price IS NOT NULL)
ORDER BY customer_name ASC, adjusted_price DESC
FETCH FIRST 100 ROWS ONLY;
