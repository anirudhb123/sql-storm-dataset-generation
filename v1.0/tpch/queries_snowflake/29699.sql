
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.s_address,
        rs.part_names
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 3
)
SELECT 
    nation_name,
    COUNT(*) AS supplier_count,
    LISTAGG(s_name || ' (' || s_address || ')', '; ') WITHIN GROUP (ORDER BY s_name) AS supplier_details,
    LISTAGG(part_names, '; ') WITHIN GROUP (ORDER BY part_names) AS supplied_parts
FROM 
    TopSuppliers
GROUP BY 
    nation_name
ORDER BY 
    nation_name;
