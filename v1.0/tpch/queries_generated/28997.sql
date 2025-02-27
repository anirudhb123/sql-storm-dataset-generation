SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Region: ', r.r_name, ' | Comment: ', r.r_comment) AS region_info
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
    p.p_name LIKE 'Rubber%'
    AND o.o_orderstatus = 'F'
    AND l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    short_name, supplier_name, region_info
HAVING 
    total_available_quantity > 100
ORDER BY 
    average_price DESC;
