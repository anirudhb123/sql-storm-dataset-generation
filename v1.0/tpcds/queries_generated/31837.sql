
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, NULL AS parent_customer, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.c_customer_sk AS parent_customer, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
HighestSales AS (
    SELECT ws_item_sk
    FROM SalesSummary
    WHERE total_sales = (SELECT MAX(total_sales) FROM SalesSummary)
),
AverageSales AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM SalesSummary
)
SELECT c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       ch.parent_customer,
       ch.level,
       ss.total_quantity,
       ss.total_sales,
       CASE
           WHEN ss.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average'
           ELSE 'Below Average'
       END AS sales_category,
       CASE 
           WHEN ss.ws_item_sk IN (SELECT * FROM HighestSales) THEN 'Top Selling Item'
           ELSE 'Regular Item'
       END AS item_category
FROM customer c
LEFT JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
LEFT JOIN SalesSummary ss ON ss.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk LIMIT 1)
WHERE c.c_first_name IS NOT NULL
ORDER BY c.c_last_name, c.c_first_name;
