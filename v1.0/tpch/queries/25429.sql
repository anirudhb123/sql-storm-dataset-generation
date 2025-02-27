SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    SUM(l.l_quantity * l.l_extendedprice) AS total_sales, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    TRIM(r.r_name) AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand%'
AND 
    l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_sales DESC, supplier_count ASC
LIMIT 50;