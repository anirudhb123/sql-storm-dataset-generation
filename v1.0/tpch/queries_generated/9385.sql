WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), ProductSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS TotalAvailable, 
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), SupplierRegion AS (
    SELECT 
        s.s_suppkey, 
        n.n_regionkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), RegionStats AS (
    SELECT 
        sr.n_regionkey, 
        COUNT(*) AS SupplierCount, 
        SUM(ps.TotalAvailable) AS TotalAvailability, 
        AVG(ps.AvgSupplyCost) AS AverageCost
    FROM 
        SupplierRegion sr
    JOIN 
        ProductSuppliers ps ON sr.s_suppkey = ps.ps_suppkey
    GROUP BY 
        sr.n_regionkey
)
SELECT 
    r.r_name AS RegionName, 
    rs.SupplierCount, 
    rs.TotalAvailability, 
    rs.AverageCost, 
    COUNT(ro.o_orderkey) AS TotalOrders,
    SUM(ro.o_totalprice) AS TotalRevenue
FROM 
    RegionStats rs
JOIN 
    region r ON rs.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    )
GROUP BY 
    r.r_name, rs.SupplierCount, rs.TotalAvailability, rs.AverageCost
ORDER BY 
    TotalRevenue DESC;
