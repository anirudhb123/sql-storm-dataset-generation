SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type,
    REPLACE(p.p_comment, 'provided', 'supplied') AS updated_comment,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_discount) AS min_discount,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
WHERE 
    p.p_size > 10 AND 
    p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    avg_supply_cost DESC, supplier_count DESC;
