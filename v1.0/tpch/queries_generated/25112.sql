SELECT
    p.p_name,
    s.s_name,
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name, ' | Available Quantity: ', ps.ps_availqty) AS detail,
    STRING_AGG(CONCAT('Customer: ', c.c_name, ', Phone: ', c.c_phone), '; ') AS customer_details
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
    p.p_size > 10 AND
    s.s_acctbal > 1000
GROUP BY
    p.p_name, s.s_name, ps.ps_availqty
ORDER BY
    ps.ps_availqty DESC, p.p_name;
