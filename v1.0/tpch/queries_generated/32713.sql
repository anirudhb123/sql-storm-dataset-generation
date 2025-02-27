WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey, s_name, s_acctbal, ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
high_value_parts AS (
    SELECT p_partkey, p_retailprice, p_type
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
total_ordered AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
customer_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ns.n_name AS nation, 
       ss.s_name AS supplier_name,
       pp.p_name AS part_name,
       COALESCE(cs.order_count, 0) AS customer_order_count,
       COALESCE(cs.total_spent, 0.00) AS customer_total_spent,
       ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ss.s_acctbal DESC) AS supplier_rank
FROM nation ns
LEFT JOIN supplier_rank ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN high_value_parts pp ON pp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN customer_summary cs ON cs.c_custkey = ss.s_suppkey
WHERE ss.rank <= 3
  AND (ss.s_acctbal IS NOT NULL AND ss.s_acctbal > 10000)
ORDER BY ns.n_name, supplier_rank;
