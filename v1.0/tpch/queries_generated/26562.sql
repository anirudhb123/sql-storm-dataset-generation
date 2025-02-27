WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_count,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation_name,
        s.suppkey,
        s.s_name,
        s.total_available_qty,
        s.unique_parts_count
    FROM 
        RankedSuppliers s
    WHERE 
        s.supplier_rank <= 5
)
SELECT 
    t.nation_name,
    STRING_AGG(t.s_name, ', ') AS top_supplier_names,
    SUM(t.total_available_qty) AS total_qty,
    SUM(t.unique_parts_count) AS unique_parts_count
FROM 
    TopSuppliers t
GROUP BY 
    t.nation_name
ORDER BY 
    t.nation_name;
