WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
    ORDER BY 
        TotalSales DESC
    LIMIT 5
)
SELECT 
    rs.s_name,
    rs.TotalSupplyCost,
    hvc.c_name,
    hvc.TotalSpent,
    tr.r_name,
    tr.TotalSales
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON rs.s_nationkey = hvc.c_nationkey
JOIN 
    TopRegions tr ON rs.s_nationkey = tr.r_regionkey
WHERE 
    rs.rn = 1
ORDER BY 
    rs.TotalSupplyCost DESC, hvc.TotalSpent DESC;
