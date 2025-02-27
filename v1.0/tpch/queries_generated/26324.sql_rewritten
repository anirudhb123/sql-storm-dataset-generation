SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%rubber%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    customer_count DESC, total_quantity DESC;