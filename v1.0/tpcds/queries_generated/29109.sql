
WITH AddressInfo AS (
    SELECT 
        ca.city AS City, 
        ca.state AS State, 
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.city IS NOT NULL AND 
        ca.state IS NOT NULL
    GROUP BY 
        ca.city, 
        ca.state
),
PromoAnalysis AS (
    SELECT 
        p.p_promo_name, 
        SUM(cs.cs_quantity) AS TotalQuantitySold, 
        SUM(cs.cs_net_profit) AS TotalNetProfit
    FROM 
        catalog_sales cs 
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        p.p_promo_name
),
FinalBenchmark AS (
    SELECT 
        ai.City, 
        ai.State, 
        ai.CustomerCount, 
        pa.p_promo_name, 
        pa.TotalQuantitySold, 
        pa.TotalNetProfit
    FROM 
        AddressInfo ai 
    LEFT JOIN 
        PromoAnalysis pa ON ai.City = LEFT(pa.p_promo_name, 3) 
    ORDER BY 
        ai.CustomerCount DESC, 
        pa.TotalNetProfit DESC
)
SELECT 
    City, 
    State, 
    CustomerCount, 
    p_promo_name, 
    TotalQuantitySold, 
    TotalNetProfit 
FROM 
    FinalBenchmark
WHERE 
    CustomerCount > 10 
ORDER BY 
    TotalNetProfit DESC;
