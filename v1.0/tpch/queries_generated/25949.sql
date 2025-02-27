SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Part: ', p.p_name, ' (Brand: ', p.p_brand, ') - Supplier: ', s.s_name, ' located in ', (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)) AS detailed_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    LOWER(p.p_comment) AS lower_case_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
WHERE 
    p.p_size > 20 AND 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_brand, p.p_comment
ORDER BY 
    total_quantity DESC, avg_extended_price ASC
LIMIT 10;
