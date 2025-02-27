WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
), PopularItems AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
), SupplierPurchases AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), AggregatedData AS (
    SELECT p.p_name, SUM(sp.total_cost) AS aggregate_cost, SUM(pi.total_sales) AS aggregate_sales
    FROM PopularItems pi
    LEFT JOIN SupplierPurchases sp ON pi.p_partkey = sp.ps_partkey
    JOIN part p ON p.p_partkey = pi.p_partkey
    GROUP BY p.p_name
)
SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(ad.aggregate_cost) AS total_cost, SUM(ad.aggregate_sales) AS total_sales
FROM AggregatedData ad
JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM SupplierPurchases ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'Widget%'))
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ad.aggregate_sales > 10000 AND (r.r_name IS NOT NULL OR r.r_name <> '') 
GROUP BY r.r_name
ORDER BY total_sales DESC, total_cost ASC;