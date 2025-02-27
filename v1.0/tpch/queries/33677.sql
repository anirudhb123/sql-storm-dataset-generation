WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
)
, OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
      AND o.o_orderdate < '1997-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    sh.s_name AS supplier_name,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(o.total_revenue, 0) DESC) AS revenue_rank,
    CASE 
        WHEN COALESCE(o.total_revenue, 0) > 10000 THEN 'High Revenue'
        WHEN COALESCE(o.total_revenue, 0) IS NULL THEN 'No Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN OrderSummary o ON o.o_orderkey = ps.ps_partkey
WHERE p.p_size >= 10 OR (p.p_type LIKE '%metal%' AND p.p_retailprice IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, sh.s_name, o.total_revenue
ORDER BY revenue_rank, p.p_partkey;