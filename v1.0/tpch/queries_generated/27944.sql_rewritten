SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_qty, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers, 
    STRING_AGG(DISTINCT CONCAT(n.n_name, '-', r.r_name), '; ') AS nations_regions
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_qty DESC, avg_supply_cost ASC;