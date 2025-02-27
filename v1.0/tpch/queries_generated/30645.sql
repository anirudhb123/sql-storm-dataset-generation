WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT ch.c_name AS customer_name,
       ch.total_orders,
       ch.total_spent,
       ps.p_name AS part_name,
       ps.total_supply_cost,
       r.nation_count AS number_of_nations
FROM CustomerOrderStats ch
JOIN PartSupplierDetails ps ON ps.rn = 1
JOIN RegionStats r ON r.nation_count IS NOT NULL
LEFT JOIN SupplierHierarchy sh ON ch.c_custkey = sh.s_suppkey
WHERE ch.total_orders > 5 AND ps.total_supply_cost > 2000.00
ORDER BY ch.total_spent DESC, ps.total_supply_cost DESC;
