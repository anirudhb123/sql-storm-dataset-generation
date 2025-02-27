
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_customer_sk, SUM(ss_net_paid) AS TotalSales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ss_customer_sk
    UNION ALL
    SELECT s.ss_customer_sk, SUM(s.ss_net_paid) AS TotalSales
    FROM store_sales s
    JOIN SalesHierarchy sh ON s.ss_customer_sk = sh.ss_customer_sk
    WHERE s.ss_sold_date_sk < sh.ss_sold_date_sk
    GROUP BY s.ss_customer_sk
), CustomerStats AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           COALESCE(SUM(sh.TotalSales), 0) AS TotalSales,
           COUNT(DISTINCT ss_ticket_number) AS TotalTransactions
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN SalesHierarchy sh ON c.c_customer_sk = sh.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status
), RankedStats AS (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY TotalSales DESC) AS SalesRank
    FROM CustomerStats
    WHERE TotalSales > 0
)

SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name,
       cs.cd_gender, cs.cd_marital_status, 
       cs.TotalSales, 
       CASE
           WHEN cs.TotalSales IS NULL THEN 'No Sales'
           WHEN cs.TotalSales > 1000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS CustomerType,
       CASE
           WHEN cs.TotalTransactions = 0 THEN '0 Transactions'
           ELSE CONCAT(cs.TotalTransactions, ' Transactions')
       END AS TransactionsInfo
FROM RankedStats cs
JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk 
WHERE ca.ca_state = 'CA'
ORDER BY cs.SalesRank, cs.TotalSales DESC
LIMIT 100
