SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM
    lineitem l
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY
    p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
