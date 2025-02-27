SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
    STRING_AGG(DISTINCT p.p_name, '; ') AS part_names, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(o.o_totalprice) AS total_order_value
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_comment LIKE '%special%' 
    AND o.o_orderdate >= '1995-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_order_value DESC;