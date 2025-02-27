
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS SalesRank,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS DenseSalesRank
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F') 
      AND ws.ws_net_paid > (
          SELECT AVG(ws2.ws_net_paid) 
          FROM web_sales ws2 
          WHERE ws2.ws_item_sk = ws.ws_item_sk
      )
),
FilteredSales AS (
    SELECT 
        RS.*,
        COALESCE(cd.cd_gender, 'U') AS CustomerGender,
        CASE 
            WHEN c.c_birth_year > 1980 THEN 'Millennial'
            ELSE 'Gen Z or Older'
        END AS AgeGroup
    FROM RankedSales RS 
    JOIN customer c ON c.c_customer_sk = RS.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    FS.web_site_sk,
    SUM(FS.ws_net_paid) AS TotalNetPaid,
    COUNT(FS.ws_order_number) AS OrderCount,
    STRING_AGG(FS.CustomerGender, ', ') AS CustomerGenders,
    AVG(FS.ws_quantity) AS AvgQuantity,
    CASE 
        WHEN SUM(FS.ws_net_paid) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS RevenueStatus,
    CASE 
        WHEN AVG(FS.ws_net_paid) < 50 THEN 'Low Value Sales'
        WHEN AVG(FS.ws_net_paid) BETWEEN 50 AND 150 THEN 'Medium Value Sales'
        ELSE 'High Value Sales'
    END AS SaleValueTier
FROM FilteredSales FS
WHERE FS.SalesRank <= 10
GROUP BY FS.web_site_sk
HAVING SUM(FS.ws_net_paid) IS NOT NULL AND COUNT(FS.ws_order_number) > 5
ORDER BY TotalNetPaid DESC
LIMIT 10;
