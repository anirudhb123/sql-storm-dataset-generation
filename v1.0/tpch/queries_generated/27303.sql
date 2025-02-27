SELECT
    p.p_name,
    s.s_name,
    c.c_name,
    CASE
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name || ': ' || r.r_comment, '; ') AS region_comments,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, l.l_returnflag
ORDER BY
    total_revenue DESC, return_status;
