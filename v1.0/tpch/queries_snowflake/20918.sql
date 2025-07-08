WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE s.s_acctbal > 1000
),
PartRevenue AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
RegionNation AS (
    SELECT r.r_regionkey, n.n_nationkey, n.n_name
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_name IS NOT NULL OR r.r_name LIKE '%America%'
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT DISTINCT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(o.total_price) AS avg_order_value,
    CASE 
        WHEN SUM(pr.revenue) > 5000 THEN 'High Revenue'
        WHEN SUM(pr.revenue) IS NULL THEN 'No Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierCTE s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN PartRevenue pr ON p.p_partkey = pr.p_partkey
LEFT JOIN OrderSummary o ON p.p_partkey = o.o_orderkey
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND (s.s_acctbal > 100 OR s.s_acctbal IS NULL)
  AND EXISTS (
      SELECT 1 
      FROM RegionNation rn 
      WHERE rn.n_nationkey = (SELECT c.c_nationkey 
                               FROM customer c 
                               WHERE c.c_custkey = o.o_orderkey)
  )
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY revenue_category DESC, supplier_count ASC;
