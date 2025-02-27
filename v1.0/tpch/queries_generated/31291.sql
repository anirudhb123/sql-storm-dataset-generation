WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey != sh.s_suppkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
LineitemSummary AS (
    SELECT l.l_orderkey, COUNT(*) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 50 AND s.s_acctbal IS NOT NULL
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    DISTINCT cs.c_name,
    n.n_name,
    p.p_name,
    COALESCE(ls.total_revenue, 0) AS revenue,
    sh.level,
    ns.supplier_count
FROM CustomerOrders cs
JOIN LineitemSummary ls ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ls.l_orderkey LIMIT 1)
JOIN PartSupplier p ON p.ps_supplycost = (SELECT MIN(ps.ps_supplycost) FROM partsupp ps)
JOIN SupplierHierarchy sh ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sh.s_nationkey LIMIT 1)
LEFT JOIN NationStats ns ON sh.s_nationkey = ns.n_nationkey
WHERE ns.supplier_count IS NOT NULL AND ns.supplier_count > 0 
ORDER BY cs.total_spent DESC, revenue ASC;
