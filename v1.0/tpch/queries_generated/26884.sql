WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        r.r_name AS region, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        RANK() OVER (PARTITION BY r.r_name ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC, SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        region, s_name, part_count, total_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
)
SELECT 
    region, 
    STRING_AGG(s_name || ' (Parts: ' || part_count || ', Cost: ' || total_supplycost || ')', '; ') AS top_suppliers
FROM 
    TopSuppliers
GROUP BY 
    region
ORDER BY 
    region;
