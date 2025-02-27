WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS depth
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'A%')

    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
AggregatedSupplier AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 100 OR AVG(s.s_acctbal) IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus,
           COUNT(l.l_linenumber) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING COUNT(l.l_linenumber) > 5
),
SupplierOrderDetails AS (
    SELECT s.s_name, os.line_count, os.total_revenue,
           NTILE(5) OVER (ORDER BY os.total_revenue DESC) AS revenue_bucket
    FROM OrderStats os
    JOIN lineitem l ON os.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
),
FinalAnalysis AS (
    SELECT nh.n_name, sos.s_name,
           ROW_NUMBER() OVER (PARTITION BY nh.n_name ORDER BY sod.total_revenue DESC) AS revenue_rank,
           sos.line_count,
           COALESCE(sos.total_revenue, 0) AS total_revenue,
           CASE WHEN sod.line_count > 10 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM NationHierarchy nh
    LEFT JOIN SupplierOrderDetails sos ON nh.n_nationkey = sos.s_nationkey
)
SELECT n.n_name, COUNT(DISTINCT f.s_name) AS supplier_count,
       SUM(f.total_revenue) AS total_revenue,
       MAX(MOD(f.line_count, 10)) AS max_line_mod,
       ARRAY_AGG(f.volume_category) AS volume_categories
FROM FinalAnalysis f
JOIN nation n ON f.n_name = n.n_name
GROUP BY n.n_name
ORDER BY supplier_count DESC
LIMIT 10;
