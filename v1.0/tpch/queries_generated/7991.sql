WITH RankedSellers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS NationName,
        rs.s_name AS SupplierName,
        rs.TotalSupplyCost
    FROM 
        RankedSellers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    WHERE 
        rs.Rank <= 3
)
SELECT 
    ts.NationName,
    ts.SupplierName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS OrdersCount
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.SupplierName = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.NationName, ts.SupplierName
ORDER BY 
    ts.NationName, TotalRevenue DESC;
