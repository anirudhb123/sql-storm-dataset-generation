SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(l.l_quantity) AS total_quantity_ordered,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
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
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_revenue DESC;