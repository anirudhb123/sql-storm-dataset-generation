SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(p.p_retailprice) AS highest_price,
    MIN(p.p_retailprice) AS lowest_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS related_nations,
    AVG(COALESCE(NULLIF(l.l_discount, 0), 1)) AS avg_discount_used
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
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 AND 
    AVG(ps.ps_supplycost) < 200
ORDER BY 
    highest_price DESC, supplier_count ASC;
