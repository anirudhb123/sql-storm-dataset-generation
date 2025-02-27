SELECT 
    CONCAT(s.s_name, ' ', p.p_name) AS supplier_part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_price ASC;