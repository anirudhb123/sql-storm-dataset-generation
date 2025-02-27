SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
    SUM(CASE WHEN p.p_retailprice > 100 THEN 1 ELSE 0 END) AS high_value_parts,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', s.s_phone, ')'), '; ') AS supplier_details,
    SUBSTRING(p.p_comment, 1, 20) AS brief_comment,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_suppliers DESC, price_rank;
