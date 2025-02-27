SELECT
    CONCAT(COALESCE(CAST(SUBSTRING(p_name, 1, 10) AS VARCHAR), ''), ' - ', COALESCE(l_shipmode, 'UNKNOWN')) AS part_ship_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(DATE_PART('day', l_receiptdate - l_shipdate)) AS avg_days_to_receive
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name LIKE 'Europe%'
    AND o.o_orderdate >= '2023-01-01'
GROUP BY
    part_ship_info
ORDER BY
    total_revenue DESC
LIMIT 10;
