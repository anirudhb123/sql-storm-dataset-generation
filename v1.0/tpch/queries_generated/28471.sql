SELECT 
    CONCAT_WS(' - ', 
        p.p_name, 
        s.s_name,
        CONCAT('R$', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)),
        COUNT(DISTINCT o.o_orderkey),
        MAX(l.l_shipdate)
    ) AS benchmark_output
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE 'ECONOMY%'
    AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    MAX(l.l_shipdate) DESC, 
    COUNT(DISTINCT o.o_orderkey) DESC
LIMIT 10;
