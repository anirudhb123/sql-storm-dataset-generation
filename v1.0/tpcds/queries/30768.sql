
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_preferred_cust_flag, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_preferred_cust_flag, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, AVG(ws.ws_sales_price) AS avg_sales_price, ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
FilteredReturns AS (
    SELECT cr.cr_item_sk, COUNT(cr.cr_return_quantity) AS total_returns, SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
RankedSales AS (
    SELECT sd.ws_item_sk, sd.total_quantity, sd.avg_sales_price,
           ROW_NUMBER() OVER (ORDER BY sd.total_quantity DESC) AS rank
    FROM SalesData sd
    JOIN FilteredReturns fr ON sd.ws_item_sk = fr.cr_item_sk
)

SELECT ch.c_first_name, ch.c_last_name, rs.total_quantity, rs.avg_sales_price, COALESCE(fr.total_returns, 0) AS total_returns, COALESCE(fr.total_return_amount, 0) AS total_return_amount
FROM CustomerHierarchy ch
LEFT JOIN RankedSales rs ON ch.c_customer_sk = rs.ws_item_sk
LEFT JOIN FilteredReturns fr ON rs.ws_item_sk = fr.cr_item_sk
WHERE rs.total_quantity > 100
ORDER BY ch.c_last_name, ch.c_first_name;
