SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_info,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    LEFT(r.r_name, 5) AS short_region_name,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
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
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_size BETWEEN 10 AND 100
    AND l.l_shipmode IN ('AIR', 'SHIP')
GROUP BY 
    p.p_name, p.p_comment, p.p_mfgr, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
