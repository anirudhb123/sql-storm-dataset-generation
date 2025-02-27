
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_addr_sk,
           c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_customer_id IN (SELECT c_customer_id
                            FROM customer
                            WHERE c_birth_year < 1990)
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_addr_sk,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer AS c
    JOIN CustomerHierarchy AS ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnsData AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt) AS total_returns,
           COUNT(sr_ticket_number) AS total_returns_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerSalesReturns AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(rd.total_returns, 0) AS total_returns
    FROM customer AS c
    LEFT JOIN SalesData AS sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN ReturnsData AS rd ON c.c_customer_sk = rd.sr_customer_sk
    WHERE c.c_birth_year IS NOT NULL
)
SELECT ch.c_first_name,
       ch.c_last_name,
       cs.total_sales,
       cs.total_returns,
       (cs.total_sales - cs.total_returns) AS net_sales,
       CASE
           WHEN cs.total_returns = 0 THEN NULL
           ELSE (cs.total_sales / NULLIF(cs.total_returns, 0)) END AS sales_return_ratio,
       ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS customer_rank
FROM CustomerHierarchy AS ch
JOIN CustomerSalesReturns AS cs ON ch.c_customer_sk = cs.c_customer_sk
WHERE ch.level = 1
ORDER BY net_sales DESC
LIMIT 10;
