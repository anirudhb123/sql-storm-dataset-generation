WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT sc.s_suppkey, sc.s_name, ps.ps_partkey, 
           CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END AS ps_availqty,
           CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END AS ps_supplycost
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.ps_partkey = ps.ps_partkey
    WHERE sc.rnk = 1 AND (sc.ps_supplycost > ps.ps_supplycost OR ps.ps_supplycost IS NULL)
),
PriceSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(COALESCE(s.s_acctbal, 0)) AS avg_balance,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY p.p_partkey, p.p_name
),
FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_comment LIKE '%important%'
),
MaxSales AS (
    SELECT p_partkey, MAX(total_sales) AS max_sales
    FROM PriceSummary
    GROUP BY p_partkey
)
SELECT ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
       COALESCE(f.avg_balance, 0) AS avg_balance,
       CASE WHEN ms.max_sales IS NOT NULL THEN 'High Performer' ELSE 'Needs Attention' END AS performance_status
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN FilteredRegions fr ON p.p_partkey = fr.r_regionkey
LEFT JOIN PriceSummary f ON p.p_partkey = f.p_partkey
LEFT JOIN MaxSales ms ON p.p_partkey = ms.p_partkey
WHERE (ps.ps_availqty IS NOT NULL OR ps.ps_supplycost IS NOT NULL)
AND (p.p_size BETWEEN 1 AND 50 OR f.total_sales IS NOT NULL)
ORDER BY COALESCE(f.total_sales, 0) DESC, ps.ps_supplycost ASC;
