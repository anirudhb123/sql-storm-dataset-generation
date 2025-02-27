SELECT 
    CONCAT('Part: ', p_name, ' | Type: ', p_type, ' | Price: $', FORMAT(p_retailprice, 2), 
           ' | Comment: ', p_comment) AS part_info,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity_ordered
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > 100.00 AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_type, p.p_retailprice, p.p_comment
ORDER BY 
    total_quantity_ordered DESC
LIMIT 10;
