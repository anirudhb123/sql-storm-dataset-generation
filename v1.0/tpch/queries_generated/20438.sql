WITH RegionSales AS (
    SELECT r.r_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (r.r_name IS NOT NULL OR r.r_name <> '')
    GROUP BY r.r_name
),

BestRegions AS (
    SELECT r_name,
           total_sales,
           order_count,
           RANK() OVER (ORDER BY total_sales DESC) AS rank_position
    FROM RegionSales
    WHERE total_sales IS NOT NULL
    AND order_count > (SELECT AVG(order_count) FROM RegionSales)
)

SELECT br.r_name,
       br.total_sales,
       br.order_count,
       (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)) AS avg_cost
FROM BestRegions br
WHERE NOT EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_acctbal < 0
    AND EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_suppkey = s.s_suppkey
        AND ps.ps_availqty < br.order_count
    )
)
ORDER BY br.rank_position, br.total_sales DESC
LIMIT 5;

WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey,
           s.s_name,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
)
SELECT * 
FROM SupplierHierarchy 
WHERE level = (SELECT MAX(level) FROM SupplierHierarchy);
