WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, level + 1
    FROM partsupp ps
    JOIN SupplierCTE s ON ps.ps_suppkey = s.s_suppkey
    WHERE level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_account_balance,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
FinalReport AS (
    SELECT ns.n_name, ns.supplier_count, ns.avg_account_balance, os.total_revenue
    FROM NationStats ns
    LEFT JOIN OrderSummary os ON ns.order_count > 0
)
SELECT f.n_name, COALESCE(f.supplier_count, 0) AS supplier_count,
       COALESCE(f.avg_account_balance, 0.00) AS avg_account_balance,
       COALESCE(f.total_revenue, 0.00) AS total_revenue,
       CASE 
           WHEN f.total_revenue > 100000 THEN 'High Revenue'
           WHEN f.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM FinalReport f
ORDER BY f.total_revenue DESC, f.n_name;
