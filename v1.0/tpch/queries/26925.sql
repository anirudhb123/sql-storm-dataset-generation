SELECT 
    s_name AS supplier_name,
    p_name AS part_name,
    SUM(l_quantity) AS total_quantity,
    AVG(ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT CONCAT(c_name, ':', c_address), '; ') AS customers_info,
    r_name AS region_name
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
    p.p_name LIKE 'rubber%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s_name, p_name, r_name
ORDER BY 
    total_quantity DESC, avg_supply_cost ASC;