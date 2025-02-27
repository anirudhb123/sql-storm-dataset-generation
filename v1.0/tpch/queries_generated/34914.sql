WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RatedPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size > 10
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    ph.p_name,
    ph.p_retailprice,
    ps.s_name AS supplier_name,
    COALESCE(os.total_revenue, 0) AS revenue,
    RANK() OVER (ORDER BY COALESCE(os.total_revenue, 0) DESC) AS revenue_rank
FROM RatedPart ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN OrderSummary os ON ph.p_partkey = os.o_orderkey
WHERE sh.level > 0
  AND (ph.p_comment IS NULL OR ph.p_comment LIKE '%special%')
ORDER BY revenue_rank
FETCH FIRST 10 ROWS ONLY;
