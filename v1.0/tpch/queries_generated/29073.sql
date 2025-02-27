SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 3), ' ', -3) AS short_comment,
    CONCAT(r.r_name, ': ', n.n_name) AS region_nation_info,
    AVG(o.o_totalprice) AS average_order_price
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
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 AND 
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, short_comment, region_nation_info
HAVING 
    supplier_count > 5
ORDER BY 
    average_order_price DESC, p.p_name;
