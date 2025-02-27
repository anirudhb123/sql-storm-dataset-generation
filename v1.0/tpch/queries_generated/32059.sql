WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal BETWEEN 5000 AND 10000
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
), HighValueOrders AS (
    SELECT os.o_orderkey, os.o_totalprice, os.lineitem_count
    FROM OrderStats os
    WHERE os.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), SupplierSupplierOrder AS (
    SELECT ss.s_suppkey, ss.s_name, os.o_orderkey, os.o_totalprice
    FROM SupplierStats ss
    JOIN lineitem l ON ss.s_suppkey = l.l_suppkey
    JOIN HighValueOrders os ON l.l_orderkey = os.o_orderkey
)
SELECT ch.c_name, ch.level, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.total_supply_cost) AS total_supply_cost
FROM CustomerHierarchy ch
LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN SupplierSupplierOrder s ON n.r_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')
GROUP BY ch.c_name, ch.level
ORDER BY ch.level, supplier_count DESC;
