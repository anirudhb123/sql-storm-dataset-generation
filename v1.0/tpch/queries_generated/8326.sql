WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 100000
)
SELECT 
    rs.s_name,
    rs.TotalSupplyCost,
    hv.c_name AS HighValueCustomer,
    hv.TotalSpent,
    hv.OrderCount
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hv ON hv.TotalSpent > 50000
WHERE 
    rs.Rank <= 5
ORDER BY 
    rs.TotalSupplyCost DESC, hv.TotalSpent DESC;
