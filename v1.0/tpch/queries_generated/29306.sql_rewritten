SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    MAX(l.l_extendedprice) AS max_extended_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ': ', p.p_comment), '; ') AS part_details
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND 
    s.s_acctbal > 1000.00
GROUP BY 
    n.n_name
ORDER BY 
    supplier_count DESC;