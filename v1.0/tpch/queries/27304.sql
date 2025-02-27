SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount_applied,
    MIN(l.l_tax) AS min_tax_applied,
    STRING_AGG(DISTINCT SUBSTRING(p.p_name, 1, 10), ', ') AS part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20 AND 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_revenue DESC;