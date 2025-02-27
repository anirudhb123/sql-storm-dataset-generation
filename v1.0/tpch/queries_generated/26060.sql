SELECT
    CONCAT(p.p_name, ' - ', s.s_name) AS product_supplier,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
WHERE
    p.p_size > 10
GROUP BY
    p.p_name, s.s_name
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_orders DESC
LIMIT 10;
