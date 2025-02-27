SELECT 
    LOWER(SUBSTRING(p.p_name, 1, 10)) AS part_substr, 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_info,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_price,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS part_comments
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
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_brand = 'BrandX' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    part_substr, supplier_info
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    avg_order_price DESC;