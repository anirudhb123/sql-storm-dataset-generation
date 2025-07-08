
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(rs.ps_supplycost * rs.ps_availqty) AS total_supply_value,
    AVG(rs.ps_supplycost) AS avg_supply_cost,
    MIN(rs.ps_supplycost) AS min_supply_cost,
    MAX(rs.ps_supplycost) AS max_supply_cost,
    LISTAGG(DISTINCT rs.p_name, ', ') WITHIN GROUP (ORDER BY rs.p_name) AS part_names
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rnk = 1
GROUP BY 
    r.r_name
ORDER BY 
    supplier_count DESC;
