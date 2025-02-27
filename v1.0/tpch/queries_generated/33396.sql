WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, d.total_cost
    FROM SupplierDetails d
    JOIN supplier s ON d.s_suppkey = s.s_suppkey
    WHERE d.total_cost > 10000
)
SELECT r.r_name,
       COUNT(DISTINCT nh.n_nationkey) AS nations_count,
       COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
       AVG(NULLIF(sd.total_cost, 0)) AS avg_supplier_cost
FROM region r
LEFT JOIN nation nh ON nh.n_regionkey = r.r_regionkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2021-01-01')
LEFT JOIN HighValueSuppliers sd ON sd.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_shipdate >= '2021-01-01')
GROUP BY r.r_name
HAVING COUNT(DISTINCT nh.n_nationkey) > 1
ORDER BY total_revenue DESC;
