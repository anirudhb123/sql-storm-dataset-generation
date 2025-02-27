SELECT
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT('Customer: ', c.c_name, ', Phone: ', c.c_phone), '; ') AS customer_info
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN
    customer c ON o.o_custkey = c.c_custkey
GROUP BY
    s.s_name, r.r_name, p.p_name
HAVING
    SUM(ps.ps_availqty) > 0
ORDER BY
    total_available_quantity DESC, average_supply_cost ASC;
