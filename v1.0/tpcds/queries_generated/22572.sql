
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS TotalNetProfit,
        COUNT(ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FilteredSales AS (
    SELECT 
        r.c_customer_id,
        COALESCE(sd.TotalNetProfit, 0) AS TotalNetProfit,
        COALESCE(sd.TotalOrders, 0) AS TotalOrders
    FROM 
        RankedCustomers r
    LEFT JOIN 
        SalesData sd ON r.c_customer_id = sd.ws_bill_customer_sk
    WHERE 
        r.PurchaseRank <= 10
),
IncomeBands AS (
    SELECT 
        hd.hd_income_band_sk,
        MIN(hd.hd_dep_count) AS MinDependentCount,
        MAX(hd.hd_dep_count) AS MaxDependentCount
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    f.c_customer_id,
    f.TotalNetProfit,
    f.TotalOrders,
    CASE 
        WHEN f.TotalNetProfit > 1000 AND f.TotalOrders > 5 THEN 'High Value'
        WHEN f.TotalNetProfit BETWEEN 500 AND 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS CustomerValue,
    ib.MinDependentCount,
    ib.MaxDependentCount,
    (SELECT 
        COUNT(DISTINCT w.ws_order_number) 
     FROM 
         web_sales w 
     WHERE 
         w.ws_ship_customer_sk = f.c_customer_id) AS DistinctOrdersFromWeb
FROM 
    FilteredSales f
LEFT JOIN 
    IncomeBands ib ON f.TotalOrders BETWEEN ib.MinDependentCount AND ib.MaxDependentCount
WHERE 
    f.TotalNetProfit IS NOT NULL OR f.TotalOrders IS NOT NULL
ORDER BY 
    f.TotalNetProfit DESC, 
    f.c_customer_id COLLATE Latin1_General_BIN
LIMIT 100;
