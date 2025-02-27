SELECT
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN LENGTH(p.p_comment) > 20 THEN 1 ELSE 0 END) AS long_comment_count,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    STRING_AGG(DISTINCT CASE WHEN LENGTH(s.s_name) > 15 THEN SUBSTRING(s.s_name, 1, 15) || '...' ELSE s.s_name END, ', ') AS supplier_names,
    MAX(o.o_totalprice) AS max_order_price,
    MIN(o.o_orderdate) AS earliest_order_date
FROM
    part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_brand LIKE 'Brand%'
    AND o.o_orderstatus = 'F'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_mfgr
ORDER BY
    supplier_count DESC, 
    avg_supplycost ASC;