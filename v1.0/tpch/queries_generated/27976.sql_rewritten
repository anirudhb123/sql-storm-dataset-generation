SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count,
    STRING_AGG(DISTINCT r.r_name, '; ') AS regions_supplied,
    MAX(o.o_orderdate) AS last_order_date
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
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    supplier_name, part_name;