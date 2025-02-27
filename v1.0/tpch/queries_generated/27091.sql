SELECT 
    CONCAT('Supplier: ', s_name, ' [', s_address, '] from Nation: ', n_name, ' (', r_name, ') - Comments: ', s_comment) AS supplier_info,
    COUNT(DISTINCT ps.part_key) AS part_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    MAX(p.p_size) AS max_part_size,
    MIN(p.p_size) AS min_part_size
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%important%'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name, s.s_comment
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5 
ORDER BY 
    total_available_quantity DESC, average_price ASC;
