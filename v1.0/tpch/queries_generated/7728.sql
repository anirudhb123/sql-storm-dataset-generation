WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name = 'ASIA'
        )
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        r.TotalSupplyCost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.SupplierRank <= 5
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    COUNT(o.o_orderkey) AS TotalOrders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue, 
    ts.s_name AS TopSupplier
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2023-12-31'
GROUP BY 
    c.c_custkey, c.c_name, ts.s_name
HAVING 
    TotalRevenue > 50000
ORDER BY 
    TotalRevenue DESC;
