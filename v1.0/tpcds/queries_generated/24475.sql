
WITH RankedSales AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        ss_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sales_price DESC) AS PriceRank,
        SUM(ss_quantity) OVER (PARTITION BY s_store_sk) AS TotalQuantity,
        COUNT(DISTINCT ss_customer_sk) OVER (PARTITION BY s_store_sk) AS UniqueCustomers
    FROM 
        store_sales
    JOIN 
        store ON ss_store_sk = s_store_sk
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20231231
),

CustomerStats AS (
    SELECT 
        c_customer_sk,
        d_count AS PurchaseCount,
        MAX(ss_sales_price) AS MaxSalePrice,
        AVG(ss_sales_price) AS AvgSalePrice
    FROM 
        store_sales 
    JOIN 
        customer ON ss_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
),

HighValueCustomers AS (
    SELECT 
        c_customer_sk
    FROM 
        CustomerStats
    WHERE 
        PurchaseCount > 5 AND
        MaxSalePrice IS NOT NULL AND
        AvgSalePrice > (SELECT AVG(ss_sales_price) FROM store_sales)
),

SalesMetrics AS (
    SELECT 
        s.s_store_name,
        COALESCE(MAX(r.PriceRank), 0) AS MaxPriceRank,
        COALESCE(SUM(cs.PurchaseCount), 0) AS TotalPurchases
    FROM 
        RankedSales r
    LEFT JOIN 
        store s ON r.s_store_sk = s.s_store_sk
    LEFT JOIN 
        CustomerStats cs ON cs.c_customer_sk IN (SELECT c_customer_sk FROM HighValueCustomers)
    GROUP BY 
        s.s_store_sk, s.s_store_name
)

SELECT 
    sm.s_store_name,
    sm.MaxPriceRank,
    sm.TotalPurchases,
    (CASE 
        WHEN sm.TotalPurchases = 0 THEN 'No Purchases' 
        ELSE 'Purchases Made' 
    END) AS PurchaseState,
    (SELECT 
        MAX(ib_upper_bound)
     FROM 
        income_band 
     WHERE 
        ib_lower_bound <= TotalPurchases AND
        ib_upper_bound IS NOT NULL) AS IncomeBand
FROM 
    SalesMetrics sm
ORDER BY 
    sm.TotalPurchases DESC, 
    sm.MaxPriceRank ASC;
