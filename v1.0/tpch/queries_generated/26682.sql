SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_name, ' ', 1), ' ', -1) AS first_word_supplier_name,
    IF(NOT(ISNULL(n.n_name)), CONCAT(n.n_name, ' ', r.r_name), 'Unknown Region') AS supplier_region
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%green%' 
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    total_quantity > 500
ORDER BY 
    total_orders DESC, avg_price ASC
LIMIT 10;
