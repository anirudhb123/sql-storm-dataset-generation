
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RegionNationStats AS (
    SELECT r.r_regionkey, r.r_name, n.n_name AS nation_name, 
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name, n.n_name
)
SELECT r.r_name AS region_name, 
       ns.supplier_count, 
       ns.total_avail_qty,
       ns.avg_supply_cost,
       cs.total_orders,
       cs.total_spent
FROM RegionNationStats r
LEFT JOIN PartSupplierStats ns ON r.r_regionkey = ns.p_partkey
LEFT JOIN CustomerOrderStats cs ON r.nation_name = cs.c_name
WHERE cs.total_spent IS NOT NULL 
  AND (ns.avg_supply_cost > 50 OR ns.supplier_count > 2)
ORDER BY cs.rank, r.r_name DESC
LIMIT 10;
