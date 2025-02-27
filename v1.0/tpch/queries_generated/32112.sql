WITH RECURSIVE supplier_rank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), high_value_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), top_customers AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
), region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT s_rank.s_suppkey) AS supplier_count,
           AVG(s_rank.s_acctbal) AS avg_acctbal
    FROM region r
    LEFT JOIN supplier_rank s_rank ON r.r_regionkey = s_rank.s_suppkey
    GROUP BY r.r_name
)
SELECT r.r_name, r.supplier_count, r.avg_acctbal, 
       COALESCE(tc.order_count, 0) AS order_count
FROM region_summary r
LEFT JOIN top_customers tc ON r.r_name = (
    SELECT n.n_name
    FROM nation n
    WHERE n.n_nationkey = (
        SELECT MIN(nationkey)
        FROM customer
    )
)
ORDER BY r.supplier_count DESC, r.avg_acctbal DESC
FETCH FIRST 10 ROWS ONLY;
