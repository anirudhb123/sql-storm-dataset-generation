
SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name FROM 1 FOR 15) AS short_part_name,
    LENGTH(p.p_comment) AS comment_length,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    MAX(l.l_extendedprice) AS max_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate > DATE '1998-10-01' - INTERVAL '1 year'
GROUP BY 
    p.p_partkey, short_part_name, comment_length, r.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    comment_length DESC, supplier_count DESC;
