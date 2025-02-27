WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY o.o_orderkey
),
CustomerSpending AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT cs.c_custkey, cs.total_spent
    FROM CustomerSpending cs
    WHERE cs.total_spent > 5000
),
NationSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY s.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
)
SELECT DISTINCT r.r_name, ns.supplier_count, rs.s_name, rs.s_acctbal
FROM region r
JOIN NationSuppliers ns ON r.r_regionkey = ns.n_nationkey
FULL OUTER JOIN RankedSuppliers rs ON rs.s_suppkey IS NULL OR ns.supplier_count > 5
WHERE r.r_name LIKE 'N%' AND ns.supplier_count IS NOT NULL
ORDER BY r.r_name, ns.supplier_count DESC, rs.rank
FETCH FIRST 10 ROWS ONLY;
