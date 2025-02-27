SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_name) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s_comment, '; ') AS combined_comments,
    MAX(l_discount) AS max_discount,
    CONCAT('Region: ', r_name, ', Nation: ', n_name) AS region_nation
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
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 1000
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    short_name, region_nation
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    average_supply_cost DESC;