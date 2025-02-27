SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS region_nation_info
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
    p.p_name LIKE '%steel%' AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC, average_retail_price ASC;