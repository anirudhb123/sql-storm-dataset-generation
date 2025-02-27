
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_current_cdemo_sk,
           0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY ws.ws_item_sk
),
FilteredSalesData AS (
    SELECT sd.*, 
           ROW_NUMBER() OVER(PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank 
    FROM SalesData sd 
    WHERE sd.total_sales > (SELECT AVG(total_sales) FROM SalesData)
    AND sd.total_orders > 10
),
HighProfitItems AS (
   SELECT fsd.ws_item_sk,
          fsd.total_sales,
          fsd.total_orders,
          fsd.total_net_profit,
          COALESCE(fsi.i_brand, 'Unknown') AS brand_name
   FROM FilteredSalesData fsd
   LEFT JOIN item fsi ON fsd.ws_item_sk = fsi.i_item_sk
   WHERE fsd.total_net_profit = (SELECT MAX(total_net_profit) 
                                  FROM FilteredSalesData)
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       hp.brand_name,
       hp.total_sales,
       hp.total_orders,
       hp.total_net_profit,
       CASE 
           WHEN hp.total_net_profit IS NULL THEN 'No Profit'
           ELSE 'Profitable'
       END AS profit_status,
       STRING_AGG(CONCAT(ch.c_first_name, ' ', ch.c_last_name), ', ') 
           FILTER (WHERE ch.level = 0) AS direct_customers
FROM CustomerHierarchy ch
JOIN HighProfitItems hp ON hp.ws_item_sk IN (
    SELECT cr_item_sk
    FROM catalog_returns cr
    WHERE cr_return_quantity > (SELECT 100 * AVG(cr_return_quantity) FROM catalog_returns)
)
GROUP BY ch.c_first_name, ch.c_last_name, hp.brand_name, hp.total_sales, hp.total_orders, hp.total_net_profit
ORDER BY hp.total_net_profit DESC
LIMIT 50;
