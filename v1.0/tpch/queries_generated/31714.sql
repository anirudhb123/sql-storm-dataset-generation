WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rh.s_name AS supplier_name,
    rh.level AS supplier_level,
    l.o_orderkey,
    li.rank,
    cs.max_order_value,
    r.nation_count,
    r.total_supply_cost
FROM SupplierHierarchy rh
JOIN RankedLineItems li ON rh.s_suppkey = li.l_suppkey
JOIN orders l ON li.l_orderkey = l.o_orderkey
JOIN RegionStats r ON rh.s_nationkey IN 
    (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.nation_count)
JOIN CustomerOrders cs ON l.o_custkey = cs.c_custkey
WHERE l.o_orderstatus = 'F'
  AND li.l_quantity > 100
  OR r.total_supply_cost IS NULL
ORDER BY supplier_name, supplier_level, max_order_value DESC;
