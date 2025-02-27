
WITH RECURSIVE SalesCTE (CustomerID, TotalSales, SalesRank) AS (
    SELECT c.c_customer_id, 
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS TotalSales,
           RANK() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS SalesRank
    FROM customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
    HAVING COALESCE(SUM(ws.ws_ext_sales_price), 0) IS NOT NULL OR c.c_customer_id IS NULL
), 
DemographicsCTE AS (
    SELECT cd.cd_gender, 
           COUNT(DISTINCT c.c_customer_id) AS CustomerCount,
           SUM(cd.cd_purchase_estimate) AS TotalPurchaseEstimate,
           RANK() OVER (ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS DemoRank
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
), 
NullLogicCTE AS (
    SELECT COALESCE(cd.cd_gender, 'Unknown') AS Gender,
           CASE 
               WHEN COUNT(c.c_customer_id) > 0 THEN 'Active'
               ELSE 'Inactive'
           END AS CustomerStatus
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT s.CustomerID,
       s.TotalSales,
       d.CustomerCount,
       d.TotalPurchaseEstimate,
       n.Gender,
       n.CustomerStatus
FROM SalesCTE s
FULL OUTER JOIN DemographicsCTE d ON d.DemoRank = s.SalesRank
LEFT JOIN NullLogicCTE n ON n.Gender = COALESCE(s.CustomerID, 'Unknown')
WHERE s.TotalSales != 0 
   OR d.CustomerCount IS NULL 
   OR n.CustomerStatus = 'Inactive'
ORDER BY s.TotalSales DESC, d.TotalPurchaseEstimate DESC
LIMIT 100 OFFSET (
    SELECT COUNT(*)
    FROM store_sales ss 
    WHERE ss.ss_net_profit IS NOT NULL 
      AND ss.ss_sales_price > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws)
) % 100;
