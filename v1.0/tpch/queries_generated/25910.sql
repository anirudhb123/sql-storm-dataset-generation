SELECT p.p_name, 
       s.s_name, 
       c.c_name, 
       o.o_orderkey, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       TRIM(UPPER(CONCAT('Order for ', p.p_name, ' from ', s.s_name))) AS order_description,
       DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS order_date_formatted,
       SUBSTRING_INDEX(c.c_address, ',', 1) AS city,
       LEFT(p.p_comment, 10) AS short_comment
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_orderstatus = 'O' 
AND l.l_returnflag = 'N'
GROUP BY p.p_name, s.s_name, c.c_name, o.o_orderkey, order_description, order_date_formatted, city, short_comment
HAVING revenue > 10000
ORDER BY revenue DESC
LIMIT 10;
