WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    AVG(fo.TotalRevenue) AS AvgTotalRevenue,
    COALESCE(SUM(r.TotSupCost), 0) AS TotalSupplierCost
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    FilteredOrders fo ON c.c_custkey = fo.o_custkey
LEFT JOIN 
    RankedSuppliers r ON c.c_nationkey = r.s_nationkey AND r.Rank <= 5
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    AvgTotalRevenue DESC;
