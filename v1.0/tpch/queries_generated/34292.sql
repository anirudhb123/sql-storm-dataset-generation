WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice) AS total_lineitem_price,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT ch.c_name, 
       ch.level, 
       r.r_name AS region, 
       COALESCE(p.avg_supply_cost, 0) AS avg_supply_cost, 
       SUM(od.total_lineitem_price) AS total_order_value
FROM CustomerHierarchy ch
JOIN TopRegions r ON ch.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN PartSupplierInfo p ON p.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN 
    (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ch.c_nationkey)) 
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ch.c_custkey)
GROUP BY ch.c_name, ch.level, r.r_name, p.avg_supply_cost
HAVING SUM(od.total_lineitem_price) > 5000
ORDER BY total_order_value DESC, ch.level;
