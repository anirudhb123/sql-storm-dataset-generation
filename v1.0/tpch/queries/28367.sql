
SELECT 
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT TRIM(p.p_name), ', ') AS part_names,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 20 
    AND l.l_shipmode IN ('AIR', 'RAIL')
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 10;
