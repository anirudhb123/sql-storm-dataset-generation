WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.n_name,
        rs.p_name,
        rs.ps_supplycost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ts.p_name,
    ts.s_name,
    ts.ps_supplycost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = ts.p_name)
WHERE 
    o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;
