SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' with comment: ', s.s_comment) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_part_comments
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE 'A%' 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND p.p_size BETWEEN 10 AND 20
GROUP BY 
    s.s_name, n.n_name, s.s_comment
ORDER BY 
    total_avail_qty DESC, average_supply_cost ASC
LIMIT 
    10;
