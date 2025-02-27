
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ' provides ', p.p_name, ' in ', p.p_container) AS supply_info,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT c.c_mktsegment, '; ') AS market_segments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%Germany%')
GROUP BY 
    p.p_name, s.s_name, p.p_container, p.p_partkey, s.s_suppkey
ORDER BY 
    total_quantity DESC, avg_price;
