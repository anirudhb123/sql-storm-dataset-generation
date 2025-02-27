SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS comments
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
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 1000.00
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity DESC
LIMIT 50;