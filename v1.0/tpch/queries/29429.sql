WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_comment,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 5000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, c.c_comment
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.r_name,
    rs.s_name,
    fc.c_name,
    fc.TotalSpent,
    COUNT(o.o_orderkey) AS OrderCount,
    STRING_AGG(DISTINCT p.p_name, ', ') AS ProductsSupplied
FROM 
    RankedSuppliers rs
JOIN 
    FilteredCustomers fc ON rs.rank = 1 
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON s.s_suppkey = rs.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON o.o_custkey = fc.c_custkey
GROUP BY 
    r.r_name, rs.s_name, fc.c_name, fc.TotalSpent
ORDER BY 
    fc.TotalSpent DESC;
