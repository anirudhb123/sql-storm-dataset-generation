WITH RecursiveCTE AS (
    SELECT s_supplierkey, s_name, s_acctbal, ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
    WHERE s_acctbal > 0
),
RankedCollections AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN (
        SELECT p1.p_partkey, COUNT(*) AS distributor_count
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        JOIN part p1 ON ps.ps_partkey = p1.p_partkey
        WHERE s.s_acctbal IS NULL OR s.s_acctbal = 0
        GROUP BY p1.p_partkey
    ) AS part_null_sup ON p.p_partkey = part_null_sup.p_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredResults AS (
    SELECT rc.s_name, rc.s_acctbal, r.p_partkey, r.total_quantity, r.total_revenue, r.order_count
    FROM RecursiveCTE rc
    JOIN RankedCollections r ON rc.rn = 1
    WHERE rc.s_acctbal IS NOT NULL AND r.total_revenue / NULLIF(r.order_count, 0) > 10000
),
FinalResults AS (
    SELECT f.s_name, f.s_acctbal, f.p_partkey,
           CASE WHEN f.total_quantity > 100 THEN 'High' ELSE 'Low' END AS quantity_status,
           CASE WHEN f.total_revenue IS NULL THEN 'No Revenue' ELSE CONCAT('$', CAST(f.total_revenue AS varchar)) END AS revenue_status
    FROM FilteredResults f
)
SELECT DISTINCT fr.s_name, fr.s_acctbal,
                fr.quantity_status, fr.revenue_status,
                RANK() OVER (ORDER BY fr.total_revenue DESC) AS revenue_rank
FROM FinalResults fr
WHERE fr.s_acctbal >= (SELECT AVG(s_acctbal)
                       FROM supplier
                       WHERE s_nationkey IN (SELECT DISTINCT n_nationkey FROM nation WHERE n_name LIKE '%land%')) 
ORDER BY fr.revenue_rank NULLS LAST;
