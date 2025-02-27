WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           CAST(s.s_name AS varchar(255)) AS full_name,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           CONCAT(sh.full_name, ' > ', s.s_name) AS full_name,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 3
),
TotalLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartialRevenue AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 5 AND 100
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT shp.s_name AS supplier_name, 
       lh.line_count AS order_count, 
       lh.total_revenue AS total_order_revenue,
       pr.p_name AS part_name,
       pr.total_cost,
       pr.supplier_count
FROM SupplierHierarchy shp
JOIN TotalLineItems lh ON lh.line_count > 25
FULL OUTER JOIN PartialRevenue pr ON pr.supplier_count > 10
WHERE pr.total_cost > 5000 OR shp.s_acctbal IS NULL
ORDER BY shp.s_name ASC, lh.total_revenue DESC, pr.p_name;
