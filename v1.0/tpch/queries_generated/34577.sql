WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

OrderTotals AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),

FilteredCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ot.total_spent
    FROM customer c
    LEFT JOIN OrderTotals ot ON c.c_custkey = ot.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
),

TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_cost DESC
    LIMIT 10
)

SELECT rh.r_name, COUNT(DISTINCT fc.c_custkey) AS rich_customers,
    (SELECT COUNT(*) FROM SupplierHierarchy) AS total_suppliers,
    (SELECT SUM(l.l_quantity) FROM lineitem l) AS total_line_items,
    tp.p_name, tp.total_cost
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredCustomer fc ON s.s_nationkey = fc.c_nationkey
CROSS JOIN TopParts tp
GROUP BY rh.r_name, tp.p_name
HAVING rich_customers > 0 AND (total_cost IS NOT NULL OR total_cost > 0)
ORDER BY rh.r_name, tp.total_cost DESC;
