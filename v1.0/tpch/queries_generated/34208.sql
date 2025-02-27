WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING total_value > 10000
),
SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS supplier_nation, r.r_name AS supplier_region
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT sr.supplier_region, COUNT(DISTINCT h.orderkey) AS high_value_order_count,
       SUM(psi.ps_supplycost * psi.ps_availqty) AS total_supply_cost
FROM SupplierRegion sr
LEFT JOIN PartSupplierInfo psi ON sr.s_suppkey = psi.ps_suppkey
LEFT JOIN HighValueOrders h ON psi.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderkey IN (SELECT o_orderkey FROM OrderHierarchy)
)
GROUP BY sr.supplier_region
ORDER BY total_supply_cost DESC, high_value_order_count DESC
LIMIT 10;
