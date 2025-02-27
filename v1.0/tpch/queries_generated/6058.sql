WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        pt.p_type,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        (SELECT DISTINCT p_type FROM part) pt ON rs.rank <= 3 AND pt.p_type = (SELECT p_type FROM part WHERE p_size = (SELECT MAX(p_size) FROM part))
)
SELECT 
    ns.n_name AS nation,
    COUNT(DISTINCT ts.s_suppkey) AS total_top_suppliers,
    SUM(ts.total_cost) AS total_spent
FROM 
    nation ns
LEFT JOIN 
    TopSuppliers ts ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ts.s_suppkey)
GROUP BY 
    ns.n_nationkey
ORDER BY 
    total_spent DESC;
