SELECT 
    p.p_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
    CONCAT(r.r_name, ' ', n.n_name) AS region_nation_info,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ls.l_extendedprice) AS avg_extended_price,
    SUM(CASE WHEN ls.l_discount > 0 THEN ls.l_extendedprice * ls.l_discount END) AS total_discounted_price
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
    lineitem ls ON p.p_partkey = ls.l_partkey
GROUP BY 
    p.p_name, region_nation_info, short_comment
HAVING 
    supplier_count > 5 AND avg_extended_price > 100
ORDER BY 
    avg_extended_price DESC, supplier_count ASC;
