
SELECT 
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    r.r_name AS region_name,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS total_returns,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS total_discounted_sales,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 1 AND 10
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, p.p_comment
ORDER BY 
    total_orders DESC, total_quantity DESC
LIMIT 50;
