WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
           MAX(l.l_shipdate) AS latest_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierRevenue AS (
    SELECT rs.s_suppkey, 
           SUM(os.total_revenue) AS supplier_revenue,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM RankedSuppliers rs
    LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN OrderStats os ON l.l_orderkey = os.o_orderkey
    GROUP BY rs.s_suppkey
),
FinalReport AS (
    SELECT sr.s_suppkey, 
           sr.s_name,
           sr.s_acctbal,
           COALESCE(sr.supplier_revenue, 0) AS supplier_revenue,
           sr.total_orders,
           CASE 
               WHEN sr.supplier_revenue IS NULL THEN 'No Revenue'
               WHEN sr.supplier_revenue > 10000 THEN 'High Revenue'
               ELSE 'Moderate Revenue'
           END AS revenue_category,
           PERCENT_RANK() OVER (ORDER BY COALESCE(sr.supplier_revenue, 0) DESC) AS revenue_rank
    FROM SupplierRevenue sr
    JOIN RankedSuppliers rs ON sr.s_suppkey = rs.s_suppkey
)
SELECT fr.*, 
       CASE 
           WHEN fr.total_orders > 5 THEN 'Frequent Supplier'
           WHEN fr.total_orders BETWEEN 1 AND 5 THEN 'Occasional Supplier'
           ELSE 'No Orders'
       END AS supplier_frequency
FROM FinalReport fr
WHERE fr.revenue_category != 'No Revenue' 
  AND fr.revenue_rank BETWEEN 0.2 AND 0.8
ORDER BY fr.revenue_rank DESC, fr.supplier_revenue DESC;
