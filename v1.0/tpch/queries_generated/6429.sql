WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS RegionName,
        ns.n_name AS NationName,
        rs.s_name AS SupplierName,
        rs.TotalSupplyCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 5
)
SELECT 
    ts.RegionName,
    ts.NationName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.SupplierName = (SELECT s.s_name FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = ts.SupplierName)))
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    ts.RegionName, ts.NationName
ORDER BY 
    ts.RegionName, TotalRevenue DESC;
