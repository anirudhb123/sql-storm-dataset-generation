WITH RECURSIVE customer_hierarchy AS (
  SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
  FROM customer c
  WHERE c.c_acctbal > 1000
  UNION ALL
  SELECT c.c_custkey, CONCAT(ch.c_name, ' & ', c.c_name), c.c_acctbal + ch.c_acctbal, c.c_nationkey, ch.level + 1
  FROM customer_hierarchy ch
  JOIN customer c ON ch.c_nationkey = c.c_nationkey AND c.c_acctbal > 1000 AND ch.c_custkey <> c.c_custkey
  WHERE ch.level < 5
),
part_supplier AS (
  SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
  FROM partsupp ps
  GROUP BY ps.ps_partkey
),
high_value_orders AS (
  SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
  FROM orders o
  JOIN lineitem l ON o.o_orderkey = l.l_orderkey
  WHERE o.o_orderstatus IN ('O', 'F')
  GROUP BY o.o_orderkey
  HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
nation_summary AS (
  SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
  FROM nation n
  LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
  GROUP BY n.n_nationkey, n.n_name
)
SELECT 
  n.n_name,
  coalesce(ch.c_name, 'No Customers') AS customer_name,
  ps.total_available,
  hv.total_value,
  ns.supplier_count,
  ns.avg_acctbal,
  CASE 
    WHEN hv.total_value IS NOT NULL THEN 'High Value'
    ELSE 'Low Value'
  END AS order_value_category
FROM nation_summary ns
LEFT JOIN customer_hierarchy ch ON ns.n_nationkey = ch.c_nationkey
LEFT JOIN part_supplier ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 20)
LEFT JOIN high_value_orders hv ON hv.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31')
WHERE ns.supplier_count > 0
ORDER BY ns.avg_acctbal DESC, ns.n_name ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM nation_summary) / 2;
