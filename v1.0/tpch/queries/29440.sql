SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_nationkey) AS nation_count,
    AVG(ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT c_mktsegment, ', ') AS market_segments,
    MAX(o_totalprice) AS max_order_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE 'Z%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    short_name
HAVING 
    COUNT(DISTINCT s_nationkey) > 1
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;