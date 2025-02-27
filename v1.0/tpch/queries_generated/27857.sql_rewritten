SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS avg_returned_value, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%steel%'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_brand, p.p_type
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_quantity DESC, supplier_count DESC;