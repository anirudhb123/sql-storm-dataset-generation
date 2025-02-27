SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;