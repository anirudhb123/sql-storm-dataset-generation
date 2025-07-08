
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
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, r.r_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    AVG(p.p_retailprice) DESC;
