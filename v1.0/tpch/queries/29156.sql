SELECT 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_part_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_part_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE '%United%' AND 
    p.p_comment NOT LIKE '%fragile%'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_nationkey
ORDER BY 
    total_available_quantity DESC, 
    avg_part_price ASC
LIMIT 10;
