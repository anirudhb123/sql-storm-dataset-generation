
WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
), SelectedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_size,
           p.p_retailprice,
           CASE 
               WHEN p.p_size < 5 THEN 'Small'
               WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
               ELSE 'Large' 
           END AS size_category
    FROM part p
    WHERE p.p_retailprice < (SELECT AVG(p_retailprice) FROM part)
), OrderDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS line_count,
           o.o_orderdate,
           o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
), CombinedResults AS (
    SELECT rp.s_suppkey,
           rp.s_name,
           sp.p_partkey,
           sp.p_name,
           sp.size_category,
           od.total_revenue,
           od.line_count
    FROM RankedSuppliers rp
    FULL OUTER JOIN SelectedParts sp ON rp.rn = 1 AND rp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sp.p_partkey LIMIT 1)
    LEFT JOIN OrderDetails od ON sp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
)
SELECT *,
       COALESCE(total_revenue, 0) AS effective_revenue,
       COALESCE(line_count, 0) * COALESCE(NULLIF(total_revenue, 0), 1) AS revenue_per_line
FROM CombinedResults
WHERE (size_category = 'Medium' OR size_category IS NULL) AND total_revenue > 500
ORDER BY effective_revenue DESC, line_count DESC;
