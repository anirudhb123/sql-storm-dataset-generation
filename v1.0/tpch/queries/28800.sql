SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
GROUP BY
    p.p_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_quantity DESC
LIMIT 10;
