WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey
    FROM 
        RankedSuppliers
    WHERE 
        Rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    p.p_name, 
    COALESCE(SUM(l.l_quantity), 0) AS TotalQuantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalRevenue,
    r.r_name AS Region,
    cs.TotalSpent
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
GROUP BY 
    p.p_name, r.r_name, cs.TotalSpent
ORDER BY 
    TotalRevenue DESC, TotalQuantity DESC
LIMIT 10;
