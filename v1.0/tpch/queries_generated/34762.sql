WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice, p_comment,
           CAST(p_name AS VARCHAR(255)) AS full_name,
           1 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment,
           CONCAT(ph.full_name, ' -> ', p.p_name),
           ph.level + 1
    FROM PartHierarchy ph
    JOIN part p ON ph.p_size < p.p_size
    WHERE ph.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ph.p_partkey, ph.p_name, ss.s_name, os.total_revenue, cs.total_orders, cs.last_order_date
FROM PartHierarchy ph
FULL OUTER JOIN SupplierStats ss ON ph.p_partkey = ss.s_suppkey
LEFT JOIN OrderSummary os ON os.o_custkey IN (SELECT c_custkey FROM customer WHERE c_name LIKE '%customer%')
LEFT JOIN CustomerStats cs ON os.o_custkey = cs.c_custkey
WHERE ss.total_available IS NOT NULL
  AND (cs.total_orders > 0 OR cs.last_order_date IS NOT NULL)
ORDER BY ph.level DESC, os.total_revenue DESC, cs.total_spent ASC
LIMIT 100;
