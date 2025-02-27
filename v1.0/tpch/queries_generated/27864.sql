SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN p.p_size BETWEEN 1 AND 10 THEN ps.ps_availqty 
        ELSE 0 
    END) AS small_parts_available,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE 'A%'
GROUP BY 
    n.n_name
ORDER BY 
    supplier_count DESC;
