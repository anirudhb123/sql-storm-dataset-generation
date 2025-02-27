SELECT
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
FROM
    part AS p
JOIN
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN
    customer AS c ON o.o_custkey = c.c_custkey
JOIN
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY
    p.p_name, s.s_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC, average_price ASC;