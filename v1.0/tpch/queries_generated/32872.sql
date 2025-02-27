WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.s_acctbal * 0.75)
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_retailprice, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_container IN ('SM CASE', 'SM BOX')
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           COUNT(DISTINCT li.l_partkey) AS part_count,
           DENSE_RANK() OVER (ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    AVG(fp.p_retailprice - fp.ps_supplycost) AS avg_price_margin,
    SUM(os.total_revenue) AS total_revenue_by_region
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN FilteredParts fp ON s.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
)
LEFT JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate > DATE '2022-01-01' OR o.o_orderstatus IS NULL
)
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_revenue_by_region DESC;
