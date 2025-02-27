SELECT
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name) AS combined_info,
    LENGTH(o.o_comment) AS order_comment_length,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status,
    DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS formatted_order_date
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY
    part_name, supplier_name, customer_name, order_number
ORDER BY
    total_revenue DESC
LIMIT 10;
