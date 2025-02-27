WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_container,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
    rs.nation_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    STRING_AGG(rs.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = ps.ps_suppkey
WHERE 
    rs.rank <= 3
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_container, rs.nation_name
ORDER BY 
    total_cost DESC;
