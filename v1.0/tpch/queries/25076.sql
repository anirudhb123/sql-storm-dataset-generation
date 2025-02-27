
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN CONCAT(c.c_name, '(', o.o_orderkey, ')') END, '; ') AS customer_returns
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%' 
AND 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment, r.r_name
ORDER BY 
    supplier_count DESC, average_supply_cost ASC;
