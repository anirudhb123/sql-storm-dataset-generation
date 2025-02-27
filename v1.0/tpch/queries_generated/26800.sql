SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_details,
    SUBSTR(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(l.l_extendedprice) AS average_ext_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_orderkey = ps.ps_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10
    AND s.s_acctbal > 1000
    AND l.l_shipdate >= '2023-01-01'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    customer_count DESC, average_ext_price DESC;
