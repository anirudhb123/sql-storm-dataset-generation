SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS max_returned_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE '%BrandA%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;