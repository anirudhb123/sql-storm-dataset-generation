WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal > sh.s_acctbal
),
AggregatedPrice AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate <= '1996-12-31'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)

SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    COALESCE(sh.s_name, 'Unknown Supplier') AS supplier_name,
    ap.total_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN AggregatedPrice ap ON ps.ps_partkey = ap.l_orderkey
WHERE p.p_size BETWEEN 10 AND 20
  AND (p.p_type LIKE '%Metal%' OR p.p_type LIKE '%Plastic%')
  AND (p.p_comment IS NOT NULL OR p.p_comment <> '')
ORDER BY total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;