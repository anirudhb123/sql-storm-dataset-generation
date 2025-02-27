SELECT
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, ' | Price: $', FORMAT(ps.ps_supplycost, 2)) AS supplier_info,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_line
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
WHERE
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    p.p_name, s.s_name, n.n_name, ps.ps_supplycost
HAVING
    total_orders > 5
ORDER BY
    total_quantity DESC
LIMIT 50;
