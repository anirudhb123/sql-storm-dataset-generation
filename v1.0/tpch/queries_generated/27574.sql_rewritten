SELECT 
    LEFT(SUBSTRING(p_name, 1, 20), 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS avg_supply_cost,
    CONCAT(r.r_name, ': ', n.n_name) AS region_nation,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_filled_orders,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_methods
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 20.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, region_nation
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC;