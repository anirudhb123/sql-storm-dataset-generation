WITH RECURSIVE CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), RegionSupplierStats AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS average_acctbal,
           MAX(s.s_acctbal) AS max_acctbal,
           MIN(s.s_acctbal) AS min_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
), LineItemStats AS (
    SELECT l.l_suppkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY l.l_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_suppkey
)
SELECT r.r_name, COALESCE(coc.order_count, 0) AS order_count,
       rss.supplier_count, rss.average_acctbal, rss.max_acctbal, rss.min_acctbal,
       lis.total_revenue, lis.revenue_rank
FROM RegionSupplierStats rss
LEFT JOIN CustomerOrderCount coc ON rss.supplier_count > 0
LEFT JOIN LineItemStats lis ON rss.supplier_count = (SELECT COUNT(*) FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = rss.r_name))
WHERE rss.supplier_count > 1 AND rss.average_acctbal IS NOT NULL 
  AND (rss.min_acctbal IS NULL OR rss.min_acctbal < 500)
ORDER BY rss.r_name, total_revenue DESC NULLS LAST;
