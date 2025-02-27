WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
FrequentParts AS (
    SELECT ps.partkey, COUNT(*) AS supply_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY ps.partkey
    HAVING COUNT(*) > 100
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT *
    FROM OrderAnalysis
    WHERE total_revenue > (SELECT AVG(total_revenue) FROM OrderAnalysis)
)
SELECT 
    s.s_suppkey,
    s.s_name,
    r.r_name AS supplier_region,
    SUM(pa.supply_count) AS total_parts_supplied,
    COUNT(DISTINCT to.o_orderkey) AS total_orders,
    AVG(order_revenue.total_revenue) AS avg_order_revenue
FROM supplier s
LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN FrequentParts pa ON s.s_suppkey = pa.ps_partkey
LEFT JOIN TopOrders to ON s.s_suppkey = to.o_orderkey
WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < 5000
GROUP BY s.s_suppkey, s.s_name, r.r_name
ORDER BY avg_order_revenue DESC;
