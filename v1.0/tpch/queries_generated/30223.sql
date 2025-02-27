WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
           o_orderpriority, o_clerk, o_shippriority, o_comment, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.orderkey, o.custkey, o.orderstatus, o.totalprice, o.orderdate,
           o.orderpriority, o.clerk, o.shippriority, o.comment, h.level + 1
    FROM orders o
    JOIN OrderHierarchy h ON o.o_orderkey = h.o_orderkey
)
SELECT c.c_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_shipdate END) AS last_returned_date,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT OUTER JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (o.o_totalprice > 1000 OR c.c_acctbal > 500)
  AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (p.p_mfgr LIKE 'Supplier%')
GROUP BY c.c_name, n.n_name
HAVING SUM(l.l_extendedprice) > 1000 OR MAX(l.l_discount) IS NULL
ORDER BY revenue DESC, c.c_name ASC;
