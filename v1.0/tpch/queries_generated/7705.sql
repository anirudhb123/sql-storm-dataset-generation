WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
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
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
) 
SELECT 
    r.r_name AS Region,
    s.s_name AS SupplierName,
    s.TotalSupplyCost,
    c.c_name AS CustomerName,
    c.TotalSpent
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueCustomers c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = s.s_suppkey))
WHERE 
    s.Rank <= 5
ORDER BY 
    r.r_name, s.TotalSupplyCost DESC, c.TotalSpent DESC;
