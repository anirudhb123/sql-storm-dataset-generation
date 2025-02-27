SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    MAX(SUBSTRING(p.p_name, 1, 10)) AS sample_part_name,
    GROUP_CONCAT(DISTINCT CONCAT(LEFT(s.s_name, 5), '...', ' (', p.p_type, ')') ORDER BY s.s_name ASC SEPARATOR '; ') AS supplier_part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00
    AND s.s_acctbal >= 2000.00
GROUP BY 
    n.n_nationkey
ORDER BY 
    unique_suppliers DESC, total_cost DESC
LIMIT 10;
