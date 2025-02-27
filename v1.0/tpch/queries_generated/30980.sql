WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           s.s_nationkey, 1 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AvailableParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT c.c_name, o.total_revenue, ns.supplier_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.total_revenue DESC) AS customer_rank
    FROM CustomerOrders c
    LEFT JOIN OrderSummary o ON c.c_custkey = o.o_orderkey
    LEFT JOIN NationStats ns ON c.c_nationkey = ns.n_nationkey
)

SELECT fs.c_name, fs.total_revenue, fs.supplier_count
FROM FinalReport fs
WHERE fs.customer_rank = 1
  AND (fs.total_revenue IS NOT NULL AND fs.supplier_count > 0)
ORDER BY fs.total_revenue DESC;
