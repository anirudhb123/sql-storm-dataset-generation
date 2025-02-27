WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT l.l_partkey) AS DistinctParts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), SupplierRegions AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_regionkey, 
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.r_name AS Region, 
    hs.s_name AS SupplierName, 
    hs.TotalSupplyCost AS SupplierCost, 
    ho.TotalSales AS OrderSales, 
    ho.DistinctParts AS PartsCount
FROM 
    RankedSuppliers hs
LEFT JOIN 
    HighValueOrders ho ON hs.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT DISTINCT 
                    l.l_partkey 
                FROM 
                    lineitem l 
                JOIN 
                    orders o ON l.l_orderkey = o.o_orderkey 
                WHERE 
                    o.o_orderkey IN (SELECT o.o_orderkey FROM HighValueOrders ho)
            )
    )
JOIN 
    SupplierRegions sr ON hs.s_nationkey = sr.n_nationkey
ORDER BY 
    sr.r_name, hs.TotalSupplyCost DESC;
