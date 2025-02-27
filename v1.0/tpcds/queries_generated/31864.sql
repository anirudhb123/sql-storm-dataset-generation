
WITH RECURSIVE TotalReturns AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
),
RecentSales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sold
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status, 
           cd.cd_gender,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 500
),
SalesWithReturns AS (
    SELECT ws.ws_item_sk,
           COALESCE(rs.total_sold, 0) AS total_sold,
           COALESCE(tr.total_returned, 0) AS total_returned,
           (COALESCE(rs.total_sold, 0) - COALESCE(tr.total_returned, 0)) AS net_sales
    FROM RecentSales rs
    FULL OUTER JOIN TotalReturns tr ON rs.ws_item_sk = tr.sr_item_sk
),
AggregatedSales AS (
    SELECT s.ws_item_sk,
           SUM(s.net_sales) AS agg_net_sales
    FROM SalesWithReturns s
    GROUP BY s.ws_item_sk
)
SELECT asales.agg_net_sales, 
       c.c_first_name,
       c.c_last_name,
       c.cd_marital_status
FROM AggregatedSales asales
JOIN CustomerDetails c ON c.c_customer_sk IN (
    SELECT DISTINCT ss.ss_customer_sk
    FROM store_sales ss
    WHERE ss.ss_item_sk = asales.ws_item_sk
    UNION
    SELECT DISTINCT ws.ws_bill_customer_sk
    FROM web_sales ws
    WHERE ws.ws_item_sk = asales.ws_item_sk
)
WHERE asales.agg_net_sales > 0
ORDER BY asales.agg_net_sales DESC
LIMIT 10;
