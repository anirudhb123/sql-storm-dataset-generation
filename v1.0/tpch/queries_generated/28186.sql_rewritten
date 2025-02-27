SELECT
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ', ', p.p_mfgr, ')'), '; ') AS part_details
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    s.s_acctbal > 5000 AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY
    total_revenue DESC;