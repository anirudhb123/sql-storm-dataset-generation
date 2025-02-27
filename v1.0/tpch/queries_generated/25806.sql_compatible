
SELECT
    CONCAT('Supplier: ', s.s_name) AS supplier_info,
    CONCAT('Part: ', p.p_name, ' (', p.p_brand, ')') AS part_info,
    CONCAT('Order: ', o.o_orderkey, ' (', o.o_orderstatus, ')') AS order_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_custkey) AS unique_customers,
    STRING_AGG(DISTINCT c.c_phone, ', ') AS customer_phones
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
    s.s_name LIKE 'Supplier%' AND
    p.p_type IN ('Type1', 'Type2') AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, o.o_orderkey, o.o_orderstatus
HAVING
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC, avg_price ASC;
