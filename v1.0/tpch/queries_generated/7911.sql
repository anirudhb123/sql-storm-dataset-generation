WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS ItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS Region,
    s.s_name AS SupplierName,
    SUM(o.ItemCount) AS TotalItemsOrdered,
    SUM(o.TotalRevenue) AS TotalRevenue,
    AVG(s.TotalSupplyCost) AS AvgSupplyCost
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderStats o ON o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = s.s_suppkey)
WHERE 
    s.rn = 1
GROUP BY 
    r.r_name, s.s_name
ORDER BY 
    Region, TotalRevenue DESC;
