WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.regionkey <> rh.r_regionkey
),
AggregatedSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY c.c_custkey, c.c_name
),
QualifiedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) < 100000
)
SELECT
    p.p_partkey,
    p.p_name,
    r.r_name AS region,
    agg.total_sales,
    qsup.s_name AS supplier_name,
    COALESCE(agg.order_count, 0) AS total_orders,
    SUM(l.l_quantity) OVER (PARTITION BY p.p_partkey ORDER BY l.l_orderkey ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN AggregatedSales agg ON agg.c_custkey = l.l_suppkey
LEFT JOIN QualifiedSuppliers qsup ON p.p_partkey = qsup.s_suppkey
JOIN RegionHierarchy r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = l.l_suppkey)
WHERE p.p_retailprice IS NOT NULL
ORDER BY region, total_sales DESC;
