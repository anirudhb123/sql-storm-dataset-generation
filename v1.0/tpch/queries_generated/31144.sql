WITH RECURSIVE supply_chain AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        ps.availqty,
        ps.supplycost,
        1 AS level
    FROM 
        partsupp ps
    UNION ALL
    SELECT 
        ps.partkey,
        ps.suppkey,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        SUM(ps.ps_supplycost) AS total_supplycost,
        level + 1
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.partkey = l.l_partkey
    JOIN 
        supply_chain sc ON sc.suppkey = ps.suppkey
    GROUP BY 
        ps.partkey, ps.suppkey, level
)
SELECT 
    p.p_name,
    SUM(sps.total_quantity) AS total_available,
    AVG(sps.total_supplycost) AS avg_supply_cost,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        ELSE CAST(p.p_size AS varchar)
    END AS size_description,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    supply_chain sps ON p.p_partkey = sps.partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = sps.suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_name, p.p_size, r.r_name
HAVING 
    SUM(sps.total_quantity) > (SELECT AVG(ps_availqty) FROM partsupp) 
ORDER BY 
    total_available DESC, size_description ASC;
