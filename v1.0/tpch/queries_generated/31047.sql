WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level
    FROM supplier 
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE shim.s_acctbal IS NOT NULL
),
AggregatedPart AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    sh.s_name AS supplier_name,
    ap.p_name,
    ap.supplier_count,
    cs.total_spent,
    cs.order_count,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No orders'
        ELSE 'Customer Active'
    END AS customer_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN AggregatedPart ap ON ap.supplier_count > 0
LEFT JOIN CustomerOrderStats cs ON cs.c_custkey = sh.s_suppkey
WHERE r.r_name LIKE '%Americas%' 
  AND (cs.total_spent > 1000 OR cs.total_spent IS NULL)
ORDER BY r.r_name, n.n_name, cs.order_count DESC;
