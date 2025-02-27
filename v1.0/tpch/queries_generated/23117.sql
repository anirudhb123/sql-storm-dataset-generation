WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        COUNT(l.l_orderkey) AS SaleCount
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
    HAVING 
        COUNT(l.l_orderkey) > 5
),
SupplierPrices AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS AvgSupplyCost,
        SUM(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS TotalNonNullSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        COUNT(ps.ps_supplycost) > 0
)
SELECT 
    c.c_name,
    COALESCE(SP.SupplierRank, 'No Supplier') AS SupplierRank,
    CP.TotalOrders,
    CP.TotalSpent,
    PP.SaleCount,
    SP.AvgSupplyCost,
    SP.TotalNonNullSupplyCost
FROM 
    CustomerPurchases CP
LEFT JOIN 
    RankedSuppliers SP ON CP.c_custkey = (SELECT s.s_custkey FROM supplier s WHERE s.s_suppkey = SP.s_suppkey LIMIT 1)
LEFT JOIN 
    PopularParts PP ON PP.p_partkey = (
        SELECT lp.l_partkey
        FROM lineitem lp
        WHERE lp.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = CP.c_custkey)
        LIMIT 1
    )
FULL OUTER JOIN 
    supplier s ON s.s_suppkey IS NOT NULL
WHERE 
    (CP.TotalSpent > 1000 OR SP.AvgSupplyCost < 50.00) 
    AND (PP.SaleCount IS NOT NULL OR PP.SaleCount < 10)
ORDER BY 
    CP.TotalSpent DESC, SupplierRank DESC
FETCH FIRST 100 ROWS ONLY;
