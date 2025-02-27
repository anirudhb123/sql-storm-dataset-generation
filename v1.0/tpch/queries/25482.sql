
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', n.n_comment), '; ') AS nation_comments,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 100
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, 
    p.p_brand,
    p.p_partkey,
    SUBSTRING(p.p_comment, 1, 20)
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC
LIMIT 50;
