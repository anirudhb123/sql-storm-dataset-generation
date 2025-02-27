
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 2000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.r_name AS region_name,
    os.total_revenue,
    os.lineitem_count,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    MAX(os.total_revenue) AS max_revenue,
    MIN(os.total_revenue) AS min_revenue,
    CASE 
        WHEN AVG(os.total_revenue) > 50000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM OrderSummary os
JOIN NationRegion nr ON nr.n_nationkey = os.o_orderkey % 10  
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = os.o_orderkey % 5  
JOIN region sr ON nr.r_name = sr.r_name
WHERE os.lineitem_count > 10
GROUP BY sr.r_name, os.total_revenue, os.lineitem_count
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY total_revenue DESC, supplier_count ASC
LIMIT 100;
