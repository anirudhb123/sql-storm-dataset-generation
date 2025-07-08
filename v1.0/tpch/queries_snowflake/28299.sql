
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_name LIKE '%widget%'
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    LISTAGG(s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS top_suppliers
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    FilteredSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE 
    c.c_acctbal > 1000
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal
ORDER BY 
    total_revenue DESC;
