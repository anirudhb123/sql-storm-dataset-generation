SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey AS order_id, 
    COUNT(DISTINCT l.l_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_type LIKE '%metal%'
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;