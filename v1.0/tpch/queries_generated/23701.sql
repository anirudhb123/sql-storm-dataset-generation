WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
), 
PartStatistics AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty, MAX(p.p_retailprice) AS max_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), 
SalesAnalysis AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_partkey) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    personal_supplier.s_name AS preferred_supplier,
    COALESCE(part_stats.total_avail_qty, 0) AS available_quantity,
    COALESCE(part_stats.max_price, 0) AS max_price,
    CASE 
        WHEN sales.total_sales > 10000 THEN 'High Performer' 
        ELSE 'Regular Performer' 
    END AS performance_category,
    rh.r_name AS region_name,
    JSON_AGG(d.n_name) FILTER (WHERE d.n_nationkey IS NOT NULL) AS nations_served
FROM part p
LEFT JOIN PartStatistics part_stats ON p.p_partkey = part_stats.p_partkey
LEFT JOIN supplier personal_supplier ON personal_supplier.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
    ORDER BY ps.ps_supplycost ASC
    LIMIT 1
)
LEFT JOIN nation d ON personal_supplier.s_nationkey = d.n_nationkey
JOIN region rh ON d.n_regionkey = rh.r_regionkey
LEFT JOIN SalesAnalysis sales ON sales.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_mktsegment = ANY (ARRAY['BUILDING', 'AUTOMOBILE'])
    )
)
GROUP BY p.p_partkey, p.p_name, personal_supplier.s_name, part_stats.total_avail_qty, 
         part_stats.max_price, sales.total_sales, rh.r_name
HAVING COUNT(DISTINCT d.n_nationkey) > 2
ORDER BY p.p_partkey DESC;
