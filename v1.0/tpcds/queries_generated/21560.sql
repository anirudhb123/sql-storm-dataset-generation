
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_returned_date_sk,
        cr_item_sk,
        cr_return_quantity,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_returned_date_sk DESC) AS ReturnRank
    FROM catalog_returns
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20221231
    GROUP BY ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(CAST(NULLIF(cd.cd_purchase_estimate, 0) AS float), 1) AS PurchaseEstimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS GenderRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    COALESCE(d.c_customer_id, 'UNKNOWN') AS CustomerID,
    d.cd_gender AS Gender,
    d.cd_marital_status AS MaritalStatus,
    SUM(COALESCE(rr.cr_return_quantity, 0)) AS TotalReturnQuantity,
    s.TotalSales AS TotalSalesAmount,
    CASE 
        WHEN d.GenderRank <= 10 THEN 'Top Buyers'
        ELSE 'Regular Buyers'
    END AS BuyerCategory,
    CASE
        WHEN mc.TotalSales > 1000 THEN 'High Value'
        WHEN mc.TotalSales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS ValueCategory,
    STRING_AGG(CONCAT('Item ', rr.cr_item_sk, ': ', COALESCE(rr.cr_return_quantity, 0)) , ', ') AS ReturnDetails
FROM Demographics d
LEFT JOIN RankedReturns rr ON rr.cr_returning_customer_sk = d.c_customer_id
LEFT JOIN SalesSummary s ON s.ws_bill_customer_sk = d.c_customer_id
LEFT JOIN (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS TotalSales 
    FROM catalog_returns 
    GROUP BY cr_returning_customer_sk
) mc ON mc.cr_returning_customer_sk = d.c_customer_id
GROUP BY d.c_customer_id, d.cd_gender, d.cd_marital_status, s.TotalSales
HAVING SUM(COALESCE(rr.cr_return_quantity, 0)) > 0 OR s.TotalSales > 0
ORDER BY TotalSalesAmount DESC, CustomerID ASC
LIMIT 100
OFFSET 10;
