WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),

BestLineItem AS (
    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM lineitem
    GROUP BY l_orderkey
),

SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

QualifiedCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)

SELECT s.s_name,
       SUM(ls.total_revenue) AS total_revenue,
       COALESCE(ss.part_count, 0) AS part_count,
       ROUND(SUM(ss.avg_supply_cost), 2) AS avg_supply_cost_per_part
FROM BestLineItem ls
JOIN QualifiedCustomers c ON ls.l_orderkey = c.c_custkey
LEFT JOIN SupplierStats ss ON c.c_custkey = ss.s_suppkey
JOIN nation n ON ss.s_nationkey = n.n_nationkey
WHERE n.n_comment IS NOT NULL
GROUP BY s.s_name
HAVING SUM(ls.total_revenue) > 100000
ORDER BY total_revenue DESC
LIMIT 10;

