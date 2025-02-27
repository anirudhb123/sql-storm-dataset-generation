SELECT 
    spl.s_name AS supplier_name, 
    p.p_name AS part_name, 
    COUNT(ps.ps_availqty) AS total_avail_qty, 
    SUM(ps.ps_supplycost) AS total_supply_cost,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    supplier spl
JOIN 
    partsupp ps ON spl.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    orders o ON p.p_partkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON spl.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%'
    AND SPLIT_PART(spl.s_comment, ' ', 1) = 'preferred'
GROUP BY 
    spl.s_name, p.p_name, r.r_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC;
