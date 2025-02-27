WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, c_mktsegment,
           1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, c.c_mktsegment,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey AND c.c_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           COUNT(li.l_orderkey) AS total_items
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_acctbal,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, s.s_acctbal
)
SELECT 
    ch.c_name,
    ch.c_acctbal,
    ch.level,
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    ss.total_available,
    ss.avg_supply_cost
FROM CustomerHierarchy ch
LEFT JOIN OrderStats os ON ch.c_custkey = os.o_orderkey
LEFT JOIN SupplierStats ss ON os.o_orderkey = ss.ps_partkey
WHERE ch.c_acctbal > 1000 AND 
      (os.total_revenue IS NOT NULL OR ss.total_available IS NOT NULL)
ORDER BY ch.level, os.total_revenue DESC
LIMIT 100;
