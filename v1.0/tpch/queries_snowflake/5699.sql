WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank <= 3 AND n.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_name = n.n_name)
)
SELECT 
    tp.nation_name,
    tp.s_name,
    tp.total_cost
FROM 
    TopSuppliers tp
JOIN 
    part p ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
    )
WHERE 
    p.p_type = 'COMPONENT'
ORDER BY 
    tp.nation_name, tp.total_cost DESC;
