WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON s.s_suppkey = c.s_suppkey
    WHERE c.level < 5
),

FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IS NOT NULL
      AND TRIM(p.p_comment) != ''
),

TotalSales AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('F', 'O') 
    GROUP BY l.l_partkey
)

SELECT coalesce(r.r_name, 'Unknown Region') AS region_name,
       np.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(tp.total_revenue) AS total_revenue,
       AVG(NULLIF(CASE WHEN sp.level IS NOT NULL THEN sp.s_acctbal ELSE 0 END, 0)) AS avg_supplier_acctbal
FROM region r
LEFT JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = np.n_nationkey
LEFT JOIN FilteredParts fp ON EXISTS (
    SELECT 1 
    FROM partsupp ps
    WHERE ps.ps_partkey = fp.p_partkey
      AND ps.ps_availqty > 0
)
LEFT JOIN TotalSales tp ON fp.p_partkey = tp.l_partkey
LEFT JOIN SupplierCTE sp ON sp.s_acctbal > 5000
WHERE c.c_acctbal IS NOT NULL
GROUP BY r.r_name, np.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY unique_customers DESC, total_revenue DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM nation) / 10;
