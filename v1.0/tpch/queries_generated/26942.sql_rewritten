SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CONCAT('Total Orders: ', COUNT(DISTINCT o.o_orderkey), ' | Total Quantity: ', SUM(l.l_quantity)) AS summary
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
    r.r_name LIKE 'S%' 
    AND n.n_name NOT LIKE '%land%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(l.l_discount) > 1000
ORDER BY 
    total_orders DESC, total_quantity DESC;