WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey,
           1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
), 
CustomerStats AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, 
           p.p_name,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationAggregates AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name,
       ps.p_name,
       stats.order_count,
       stats.total_spent,
       sh.level,
       CASE 
           WHEN sh.level IS NOT NULL THEN 'In Hierarchy'
           ELSE 'Not in Hierarchy'
       END AS status
FROM CustomerStats stats
JOIN PartSupplier ps ON stats.order_count > 5
FULL OUTER JOIN NationAggregates n ON stats.order_count > 3 AND n.total_acctbal BETWEEN 5000 AND 15000
LEFT JOIN SupplierHierarchy sh ON stats.c_custkey = sh.s_suppkey
WHERE n.supplier_count > 0 
ORDER BY n.n_name, ps.p_name;
