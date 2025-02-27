
SELECT 
    CONCAT(SUBSTRING(p.p_name FROM 1 FOR 20), '...') AS short_name,
    s.s_name AS supplier_name,
    STRING_AGG(DISTINCT n.n_name) AS nations_of_suppliers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment ILIKE '%fragile%'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_suppkey
ORDER BY 
    total_quantity DESC
LIMIT 10;
