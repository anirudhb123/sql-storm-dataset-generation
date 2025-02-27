SELECT
    p.p_name,
    p.p_mfgr,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_discounted_price,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_partkey, p.p_name, p.p_mfgr
ORDER BY
    supplier_count DESC, avg_supply_cost ASC;