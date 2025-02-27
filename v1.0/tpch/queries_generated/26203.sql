SELECT
    CONCAT(s.s_name, ' | ', c.c_name) AS supplier_customer,
    SUBSTRING_INDEX(s.s_address, ',', 1) AS supplier_city,
    DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS order_date,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(substring(l.l_comment, 1, 20)) AS sample_comment
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
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    s.s_acctbal > 0
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    supplier_customer, supplier_city, order_date
HAVING
    total_revenue > 10000
ORDER BY
    total_revenue DESC
LIMIT 10;
