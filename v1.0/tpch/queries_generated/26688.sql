SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_availability,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS suppliers,
    LEFT(p.p_comment, 10) AS short_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info
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
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_availability DESC, avg_supply_cost ASC;
