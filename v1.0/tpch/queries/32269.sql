WITH RECURSIVE supply_chain AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 0 AS level
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, level + 1
    FROM partsupp ps
    JOIN supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE sc.level < 5
), supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(s.s_acctbal) as total_acctbalance
    FROM supplier s
    JOIN supply_chain sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), order_stats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity, COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), customer_revenue AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT n.n_name, r.r_name, COALESCE(ss.total_acctbalance, 0) AS supplier_balance, 
       COALESCE(cr.total_spent, 0) AS customer_expenditure,
       os.total_revenue, os.avg_quantity, os.line_count
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_summary ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN customer_revenue cr ON n.n_nationkey = cr.c_custkey
JOIN order_stats os ON os.total_revenue > 1000
WHERE r.r_name LIKE 'North%'
  AND (ss.total_acctbalance IS NOT NULL OR cr.total_spent IS NOT NULL) 
ORDER BY ss.total_acctbalance DESC, cr.total_spent ASC
LIMIT 10;
