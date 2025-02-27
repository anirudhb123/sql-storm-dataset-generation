SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    CONCAT(n.n_name, ': ', r.r_name) AS region_info,
    AVG(CASE 
        WHEN LENGTH(ps.ps_comment) > 20 THEN ps.ps_supplycost 
        ELSE NULL 
        END) AS avg_cost_long_comments,
    MAX(l.l_shipdate) AS latest_ship_date,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_container LIKE '%BOX%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, region_info
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    unique_suppliers DESC, avg_cost_long_comments ASC;