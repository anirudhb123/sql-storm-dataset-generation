
SELECT
    p.p_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    COUNT(l.l_orderkey) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) * 100 AS average_discount_percentage,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments,
    CONCAT('Order ', o.o_orderkey, ' for part ', p.p_name) AS order_description
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_type LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING
    SUM(l.l_extendedprice) > 1000
ORDER BY
    total_extended_price DESC;
