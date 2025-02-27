SELECT 
    TRIM(SUBSTRING(p.p_name, 1, 20)) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    LEFT(r.r_name, 5) || '...' AS region_prefix,
    CONCAT('Total Price: ', FORMAT(SUM(o.o_totalprice), 'C')) AS total_price_formatted
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
GROUP BY 
    TRIM(SUBSTRING(p.p_name, 1, 20)), 
    LEFT(r.r_name, 5) || '...'
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 
ORDER BY 
    avg_supplycost DESC;
