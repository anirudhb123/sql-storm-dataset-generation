WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 10000 AND sh.level < 5
), 
PartAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_type LIKE 'type%'
    )
    GROUP BY ps.ps_partkey
), 
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(o.total_price) AS avg_order_value,
       p.total_avail_qty, p.avg_supply_cost,
       COALESCE(sh.s_name, 'N/A') AS supplier_name
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderStats o ON c.c_custkey = o.o_orderkey
LEFT JOIN PartAggregation p ON o.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_quantity > 50
)
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, p.total_avail_qty, p.avg_supply_cost, sh.s_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY r.r_name;
