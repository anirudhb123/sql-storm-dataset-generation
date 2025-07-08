
WITH RECURSIVE supplier_hierarchy AS (
  SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
  FROM supplier s
  WHERE s.s_acctbal >= 10000
  UNION ALL
  SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
  FROM supplier s
  JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
  WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 5
),
nation_stats AS (
  SELECT n.n_nationkey, n.n_name, 
         COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
         AVG(s.s_acctbal) AS avg_acctbal
  FROM nation n
  LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
  GROUP BY n.n_nationkey, n.n_name
),
order_info AS (
  SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
         DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
  FROM orders o
  JOIN lineitem l ON o.o_orderkey = l.l_orderkey
  GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
)
SELECT ns.n_name, ns.supplier_count, ns.avg_acctbal, oi.total_lineitem_value,
       COUNT(DISTINCT oi.o_orderkey) AS order_count
FROM nation_stats ns
JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
JOIN order_info oi ON oi.o_totalprice > ns.avg_acctbal
WHERE ns.supplier_count > 5
  AND EXTRACT(YEAR FROM oi.o_orderdate) = 1997
GROUP BY ns.n_name, ns.supplier_count, ns.avg_acctbal, oi.total_lineitem_value
HAVING AVG(oi.total_lineitem_value) > 5000
ORDER BY ns.n_name ASC, order_count DESC
LIMIT 10;
