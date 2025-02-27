WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS BrandRank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopBrands AS (
    SELECT 
        p_brand,
        COUNT(*) AS PartsCount,
        SUM(TotalSupplyCost) AS TotalCostAcrossParts
    FROM 
        RankedParts
    WHERE 
        BrandRank <= 5
    GROUP BY 
        p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
)
SELECT 
    rb.p_brand,
    tb.PartsCount,
    tb.TotalCostAcrossParts,
    co.OrderCount,
    co.TotalSpent
FROM 
    TopBrands tb
JOIN 
    RankedParts rb ON tb.p_brand = rb.p_brand
JOIN 
    CustomerOrders co ON rb.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 10
    )
ORDER BY 
    tb.TotalCostAcrossParts DESC, 
    co.TotalSpent DESC;
