
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 1 AS depth
    FROM income_band
    UNION ALL
    SELECT i.ib_income_band_sk, 
           (i.ib_lower_bound * 0.9) AS ib_lower_bound, 
           (i.ib_upper_bound * 1.1) AS ib_upper_bound, 
           depth + 1
    FROM IncomeRanges ir
    JOIN income_band i ON ir.ib_income_band_sk = i.ib_income_band_sk
    WHERE depth < 5
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS Gender,
        COALESCE(cd.cd_marital_status, 'N') AS MaritalStatus,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_item_sk) AS UniqueItemsPurchased,
        RANK() OVER (PARTITION BY COALESCE(cd.cd_gender, 'U') ORDER BY SUM(ws.ws_sales_price) DESC) AS SalesRank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TransactionStats AS (
    SELECT 
        cs.cs_customer_sk AS CustomerSK,
        SUM(cs.cs_net_profit) AS TotalProfit,
        COUNT(DISTINCT cs.cs_order_number) AS OrderCount,
        SUM(cs.cs_quantity) AS TotalQuantity
    FROM catalog_sales cs
    GROUP BY cs.cs_customer_sk
)
SELECT 
    cs.CustomerSK,
    cs.Gender,
    cs.MaritalStatus,
    COALESCE(t.TotalProfit, 0) AS TotalProfit,
    COALESCE(t.OrderCount, 0) AS OrderCount,
    COALESCE(t.TotalQuantity, 0) AS TotalQuantity,
    ir.ib_income_band_sk,
    ir.ib_lower_bound,
    ir.ib_upper_bound,
    CASE 
        WHEN TotalSales > 10000 THEN 'High Income'
        WHEN TotalSales BETWEEN 5000 AND 10000 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS IncomeCategory
FROM CustomerStats cs
LEFT JOIN TransactionStats t ON cs.c_customer_sk = t.CustomerSK
LEFT JOIN IncomeRanges ir ON cs.TotalSales BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
WHERE cs.SalesRank <= 5
ORDER BY cs.Gender, TotalSales DESC, cs.CustomerSK;
