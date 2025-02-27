SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CONCAT_WS(':', p.p_mfgr, p.p_brand, p.p_type, p.p_container) ORDER BY p.p_partkey SEPARATOR '; '), '; ', 3) AS part_details,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_shipdate) AS latest_ship_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    s.s_name, p.p_name
HAVING 
    total_orders > 0 
ORDER BY 
    total_revenue DESC, supplier_name ASC
LIMIT 10;
