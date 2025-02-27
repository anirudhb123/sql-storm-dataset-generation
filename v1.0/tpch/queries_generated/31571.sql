WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(COALESCE(ps.total_avail_qty, 0)) AS regional_parts_available,
    AVG(COALESCE(cs.total_spent, 0)) AS avg_customer_spent,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN PartStats ps ON n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c)
LEFT JOIN CustomerOrderStats cs ON cs.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY r.r_name
HAVING AVG(COALESCE(cs.total_spent, 0)) > 1000
ORDER BY region_count DESC, r.r_name;
