WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND sh.depth < 5
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, p.p_type, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '30 DAY'
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, ROW_NUMBER() OVER (ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT r.r_name, SUM(ps.ps_supplycost) AS total_supply_cost,
       AVG(ps.ps_availqty) AS avg_availability,
       COUNT(DISTINCT c.c_custkey) AS distinct_customers,
       MAX(c.total_spent) AS max_spent_by_customer,
       MAX(s.depth) AS max_supplier_depth,
       STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_type, ')'), ', ') AS part_summary
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN PartSummary p ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerOrderDetails c ON c.c_custkey = (SELECT c2.c_custkey FROM customer c2 WHERE c2.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING SUM(ps.ps_supplycost) > 5000 AND MAX(s.depth) IS NOT NULL
ORDER BY total_supply_cost DESC;
