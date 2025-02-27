SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_comment FROM 1 FOR 20), '; ') AS sampled_supplier_comments,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(o.o_orderdate) AS latest_order_date,
    MIN(o.o_orderdate) AS earliest_order_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
AND 
    o.o_orderstatus IN ('O', 'P')
GROUP BY 
    p.p_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
