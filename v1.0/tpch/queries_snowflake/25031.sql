
SELECT 
    p_mfgr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    LISTAGG(DISTINCT c.c_mktsegment, ', ') WITHIN GROUP (ORDER BY c.c_mktsegment) AS market_segments,
    RANK() OVER (PARTITION BY p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
GROUP BY 
    p_mfgr, p_type, p.p_partkey
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    revenue_rank, p_mfgr;
