WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count, 
        SUM(ps.ps_availqty) AS total_availqty,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        ranking <= 10
),
CustomerSales AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    ts.s_name AS supplier_name, 
    cs.c_name AS customer_name, 
    cs.total_spent, 
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer cs ON o.o_custkey = cs.c_custkey
GROUP BY 
    ts.s_name, cs.c_name, cs.total_spent
ORDER BY 
    cs.total_spent DESC;
