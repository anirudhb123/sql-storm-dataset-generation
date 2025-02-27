WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2020-01-01' AND o.o_orderdate < DATE '2021-01-01'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 5000
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 20000
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_name AS part_name,
    COALESCE(SUM(os.total_revenue), 0) AS total_order_revenue,
    COALESCE(SUM(ps.supplycount), 0) AS total_suppliers,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM TopCustomers c WHERE c.total_spent > 50000) AS high_value_customers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN PartSupplierInfo p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 50)
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_discount > 0.1)
LEFT JOIN (SELECT s.s_suppkey, COUNT(*) AS supplycount FROM SupplierHierarchy s GROUP BY s.s_suppkey) ps ON ps.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
GROUP BY r.r_name, n.n_name, p.p_name
ORDER BY region_name, total_order_revenue DESC, total_suppliers ASC
LIMIT 100;
