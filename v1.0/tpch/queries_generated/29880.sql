SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    p.p_size, 
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_extended_price DESC
LIMIT 10;
