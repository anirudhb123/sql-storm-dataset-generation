WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderkey
),
AvgSupplyCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_partkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_size, AVG(l.l_extendedprice) OVER (PARTITION BY p.p_partkey) AS avg_price,
           ROW_NUMBER() OVER (ORDER BY AVG(l.l_extendedprice) DESC) AS rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
)
SELECT s.s_name, 
       r.r_name, 
       COALESCE(SUM(os.total_revenue), 0) AS total_order_revenue,
       COALESCE(SUM(rc.avg_cost), 0) AS avg_supply_cost,
       p.p_name, 
       p.rank
FROM SupplierHierarchy s
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderSummary os ON s.s_suppkey = os.o_orderkey
LEFT JOIN AvgSupplyCost rc ON rc.ps_partkey = s.s_suppkey
JOIN RankedParts p ON p.p_partkey = os.o_orderkey
WHERE s.s_acctbal IS NOT NULL AND p.rank <= 10
GROUP BY s.s_name, r.r_name, p.p_name, p.rank
ORDER BY r.r_name, total_order_revenue DESC;
