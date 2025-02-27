WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c 
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey AND c.c_custkey <> ch.c_custkey
    WHERE ch.level < 5
),
PartSupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ch.c_name AS customer_name,
       ch.level AS customer_level,
       r.r_name AS region_name,
       ps.p_name AS part_name,
       pc.total_supply_cost,
       os.total_revenue
FROM CustomerHierarchy ch
LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN part ps ON ps.p_partkey IN (SELECT temp.ps_partkey FROM PartSupplierCost temp WHERE temp.total_supply_cost < 1000)
LEFT JOIN OrderSummary os ON os.o_orderkey = ch.c_custkey
WHERE r.r_name IS NOT NULL AND os.total_revenue IS NOT NULL
ORDER BY ch.customer_level, total_revenue DESC
LIMIT 100;
