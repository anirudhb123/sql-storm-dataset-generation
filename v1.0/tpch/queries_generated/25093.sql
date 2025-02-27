SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', COUNT(DISTINCT p.p_partkey), ' different parts.'),
    AVG(p.p_retailprice) AS average_retail_price,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    average_retail_price DESC;
