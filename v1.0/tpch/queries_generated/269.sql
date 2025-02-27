WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    AND 
        o.o_orderdate >= '2023-01-01'
)
SELECT 
    n.n_name AS Nation, 
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders, 
    SUM(co.o_totalprice) AS TotalRevenue,
    MAX(rs.TotalCost) AS MaxSupplierCost
FROM 
    nation n
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey) 
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rn = 1
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    SUM(co.o_totalprice) > 10000
ORDER BY 
    TotalRevenue DESC;
