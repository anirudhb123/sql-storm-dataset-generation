SELECT 
    n.n_name AS nation_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(l.l_quantity) AS average_quantity, 
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names 
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l.l_returnflag = 'N' 
GROUP BY 
    n.n_name 
ORDER BY 
    total_revenue DESC, 
    nation_name ASC
LIMIT 10;