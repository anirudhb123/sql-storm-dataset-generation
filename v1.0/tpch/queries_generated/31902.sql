WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.custkey <> ch.c_custkey AND c.c_acctbal > 1000
),
SupplierWithAverageCost AS (
    SELECT ps.s_suppkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
RevenueByRegion AS (
    SELECT n.n_name, SUM(os.total_revenue) AS total_revenue
    FROM OrderSummary os
    JOIN customer c ON os.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT rh.r_name AS region_name,
       SUM(COALESCE(rv.total_revenue, 0)) AS total_revenue,
       COUNT(DISTINCT ch.c_custkey) AS active_customers,
       COUNT(DISTINCT sw.s_suppkey) AS suppliers_count,
       AVG(sw.avg_supplycost) AS average_supplier_cost
FROM region rh
LEFT JOIN RevenueByRegion rv ON rh.r_name = rv.n_name
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey = ch.c_nationkey
)
LEFT JOIN SupplierWithAverageCost sw ON sw.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100
)
GROUP BY rh.r_name
ORDER BY total_revenue DESC;
