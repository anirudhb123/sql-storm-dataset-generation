WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT r.r_name, SUM(l.l_extendedprice) AS region_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_name
    HAVING SUM(l.l_extendedprice) > (
        SELECT AVG(total_revenue) FROM OrderSummary
    )
),
FinalOutput AS (
    SELECT sr.s_name, sr.level, tr.region_revenue
    FROM SupplierHierarchy sr
    JOIN TopRegions tr ON sr.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = 'United States'
    )
)
SELECT 
    f.s_name,
    f.level,
    COALESCE(f.region_revenue, 0) AS region_revenue,
    ROW_NUMBER() OVER (PARTITION BY f.level ORDER BY f.region_revenue DESC) AS rank
FROM FinalOutput f
ORDER BY f.level, region_revenue DESC;
