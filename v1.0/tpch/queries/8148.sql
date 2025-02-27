WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        *, 
        RANK() OVER (PARTITION BY nation_name ORDER BY total_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers
    WHERE 
        total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    fs.s_name AS top_supplier_name, 
    fs.total_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    FilteredSuppliers fs ON fs.s_suppkey = (
        SELECT s_suppkey 
        FROM FilteredSuppliers 
        WHERE supplier_rank = 1 AND nation_name = (SELECT n_name FROM nation WHERE n_nationkey = c.c_nationkey)
    )
WHERE 
    o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
ORDER BY 
    o.o_orderdate DESC, c.c_custkey ASC;