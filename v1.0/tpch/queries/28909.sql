SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(p.p_retailprice) AS highest_retail_price,
    MIN(p.p_retailprice) AS lowest_retail_price,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey AND l.l_partkey = p.p_partkey
    )
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC;
