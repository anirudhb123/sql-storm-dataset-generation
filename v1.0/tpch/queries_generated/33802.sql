WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 2000.00 AND sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS total_items,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT s.s_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(os.total_revenue) AS total_order_revenue,
    AVG(sr.supplier_revenue) AS avg_supplier_revenue,
    MAX(sr.supplier_revenue) AS max_supplier_revenue,
    MIN(sr.supplier_revenue) AS min_supplier_revenue,
    CASE 
        WHEN MAX(sr.supplier_revenue) IS NULL THEN 'No Supplier Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN SupplierRevenue sr ON sr.s_suppkey IN (
    SELECT sh.s_suppkey 
    FROM SupplierHierarchy sh
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_order_revenue DESC;
