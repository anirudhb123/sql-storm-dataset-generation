WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY n.n_name ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
)

SELECT 
    r.r_name,
    COUNT(DISTINCT rs.s_suppkey) AS total_suppliers,
    SUM(rs.part_count) AS total_parts,
    STRING_AGG(CONCAT(rs.s_name, ' (', rs.part_count, ' parts)'), ', ') AS supplier_summary
FROM 
    region r
LEFT JOIN 
    RankedSuppliers rs ON r.r_name = rs.nation_name
GROUP BY 
    r.r_name
ORDER BY 
    total_parts DESC;
