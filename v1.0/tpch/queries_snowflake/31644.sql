
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 10000
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY o.o_orderkey
),
NationsWithSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 0
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, ns.supplier_count,
           ROW_NUMBER() OVER (ORDER BY ns.supplier_count DESC) AS nation_rank
    FROM NationsWithSuppliers ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
)
SELECT th.n_name, th.supplier_count, sh.level,
       CASE 
           WHEN th.supplier_count > 10 THEN 'High'
           ELSE 'Low'
       END AS supplier_segment,
       os.total_revenue
FROM TopNations th
LEFT JOIN SupplierHierarchy sh ON th.n_nationkey = sh.s_nationkey
LEFT JOIN OrderStats os ON os.o_orderkey = th.n_nationkey
WHERE th.nation_rank <= 5
ORDER BY th.supplier_count DESC, sh.level ASC;
