
WITH RECURSIVE SalesCTE AS (
    SELECT ss_store_sk, SUM(ss_net_paid) AS TotalSales, COUNT(ss_ticket_number) AS SalesCount
    FROM store_sales
    GROUP BY ss_store_sk
    UNION ALL
    SELECT s.ss_store_sk, s.ss_net_paid + c.TotalSales, c.SalesCount + 1
    FROM store_sales s
    INNER JOIN SalesCTE c ON s.ss_store_sk = c.ss_store_sk
    WHERE s.ss_ticket_number > c.SalesCount
),
CustomerAnalysis AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COALESCE(CAST(SUM(ws.ws_net_paid) / NULLIF(COUNT(ws.ws_order_number), 0) AS DECIMAL(10,2)), 0) AS AvgSpend,
           COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT ca.c_customer_sk, ca.AvgSpend, ca.OrderCount,
           ROW_NUMBER() OVER (PARTITION BY ca.cd_gender ORDER BY ca.AvgSpend DESC) AS GenderRank
    FROM CustomerAnalysis ca
    WHERE ca.AvgSpend > (
        SELECT AVG(AvgSpend) FROM CustomerAnalysis
    )
)
SELECT s.ss_store_sk, s.TotalSales, s.SalesCount,
       tc.c_customer_sk, tc.AvgSpend, tc.OrderCount
FROM SalesCTE s
FULL OUTER JOIN TopCustomers tc ON s.ss_store_sk = tc.c_customer_sk
WHERE (s.TotalSales IS NOT NULL OR tc.AvgSpend IS NOT NULL)
AND (s.SalesCount + COALESCE(tc.OrderCount, 0) > 20)
ORDER BY s.TotalSales DESC NULLS LAST, tc.AvgSpend DESC NULLS LAST;
