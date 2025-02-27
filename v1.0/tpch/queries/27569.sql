SELECT 
    SUBSTR(p.p_name, 1, 10) AS short_name,
    COUNT(ps.ps_partkey) AS supplier_count,
    AVG(o.o_totalprice) AS avg_order_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_list
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-10-31'
GROUP BY 
    short_name, region_name
HAVING 
    COUNT(ps.ps_partkey) > 5
ORDER BY 
    avg_order_price DESC;