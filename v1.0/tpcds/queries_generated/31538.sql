
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_returned_revenue
    FROM store_returns
    GROUP BY sr_item_sk
),
FilteredSales AS (
    SELECT sd.ws_item_sk,
           sd.total_sold,
           sd.total_revenue,
           COALESCE(rd.total_returns, 0) AS total_returns,
           COALESCE(rd.total_returned_revenue, 0) AS total_returned_revenue
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.sr_item_sk
),
FinalReport AS (
    SELECT ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
           fs.ws_item_sk,
           fs.total_sold,
           fs.total_revenue,
           fs.total_returns,
           fs.total_returned_revenue,
           (fs.total_revenue - fs.total_returned_revenue) AS net_revenue
    FROM FilteredSales fs
    LEFT JOIN CustomerHierarchy ch ON ch.level = 0
    ORDER BY customer_name, net_revenue DESC
)
SELECT *
FROM FinalReport
WHERE net_revenue > 1000
  AND (total_returns IS NULL OR total_returns < 5)
ORDER BY customer_name, total_sold DESC;
