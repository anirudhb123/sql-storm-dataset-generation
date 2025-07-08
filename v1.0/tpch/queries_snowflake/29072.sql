
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(ps.ps_partkey) AS part_count,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM 
        RankedSuppliers s
)
SELECT 
    n.n_name AS nation_name, 
    ts.s_name AS supplier_name, 
    ts.part_count, 
    ts.part_names, 
    ts.total_supply_value
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.s_nationkey = n.n_nationkey
WHERE 
    ts.rank <= 5
ORDER BY 
    n.n_name, ts.total_supply_value DESC;
