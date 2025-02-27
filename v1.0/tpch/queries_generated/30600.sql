WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SalesData AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
DistinctNations AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    r.r_name,
    p.p_brand,
    p.p_name,
    COALESCE(pc.supplier_count, 0) AS total_suppliers,
    SUM(sd.revenue) AS total_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(sd.revenue) DESC) AS brand_rank
FROM part p
LEFT JOIN PartSupplierCount pc ON p.p_partkey = pc.ps_partkey
JOIN SalesData sd ON sd.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0.05
)
CROSS JOIN region r
LEFT JOIN supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN (SELECT n_name FROM DistinctNations))
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY r.r_name, p.p_brand, p.p_name
HAVING SUM(sd.revenue) > 10000
ORDER BY total_revenue DESC, brand_rank
LIMIT 10;
