
SELECT 
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_quantity) AS total_quantity_sold,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    AVG(o.o_totalprice) AS average_order_value
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
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_retailprice > 100
GROUP BY 
    s.s_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    unique_customers DESC, total_quantity_sold ASC;
