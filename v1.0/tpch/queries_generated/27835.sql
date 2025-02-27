SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment,
    DATE_FORMAT(o.o_orderdate, '%Y-%m') AS order_month,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name LIKE '%land%'
    )
    AND o.o_orderstatus = 'O'
GROUP BY part_name, supplier_name, customer_name, order_month
HAVING total_sales > 10000
ORDER BY total_sales DESC, order_month ASC;
