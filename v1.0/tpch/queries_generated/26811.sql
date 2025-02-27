WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    r.r_name AS region, 
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count, 
    SUM(rs.total_supply_value) AS total_supply_value 
FROM 
    RankedSuppliers rs
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey))
WHERE 
    rs.rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_value DESC;
