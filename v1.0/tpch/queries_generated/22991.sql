WITH RecursiveMarketSegment AS (
    SELECT c.c_mktsegment,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100
    GROUP BY c.c_mktsegment
    HAVING SUM(o.o_totalprice) IS NOT NULL
), NationsWithNoSuppliers AS (
    SELECT n.n_nationkey,
           n.n_name,
           (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey = n.n_nationkey) AS supplier_count
    FROM nation n
    WHERE NOT EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
), PartSupplierOrders AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING total_lineitem_value IS NOT NULL
), CombinedResults AS (
    SELECT rms.c_mktsegment,
           rms.order_count,
           rms.total_revenue,
           nwn.supplier_count,
           pso.total_lineitem_value
    FROM RecursiveMarketSegment rms
    FULL OUTER JOIN NationsWithNoSuppliers nwn ON rms.c_mktsegment IS NOT NULL
    FULL OUTER JOIN PartSupplierOrders pso ON pso.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size BETWEEN 1 AND 10
          AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
    )
    WHERE (rms.order_count > 5 OR nwn.supplier_count = 0)
)
SELECT c_mktsegment,
       MAX(order_count) OVER (PARTITION BY c_mktsegment),
       SUM(COALESCE(total_revenue, 0)) AS total_revenue,
       COUNT(DISTINCT CASE WHEN supplier_count IS NULL THEN n_name END) AS nations_without_suppliers,
       SUM(total_lineitem_value) AS total_value
FROM CombinedResults
GROUP BY c_mktsegment
HAVING COUNT(DISTINCT c_mktsegment) < 5 OR MAX(total_lineitem_value) IS NULL
ORDER BY total_revenue DESC NULLS LAST;
