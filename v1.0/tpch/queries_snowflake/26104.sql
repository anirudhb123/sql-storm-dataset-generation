
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_address,
    CASE 
        WHEN p.p_retailprice > 1000 THEN 'Expensive'
        WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Average'
        ELSE 'Cheap'
    END AS price_category,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    LISTAGG(DISTINCT c.c_name, '; ') WITHIN GROUP (ORDER BY c.c_name) AS customer_names
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
    r.r_name LIKE 'N%' 
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name, r.r_name, p.p_retailprice
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_extended_price DESC;
