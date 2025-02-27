WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_custkey
),
RegionNation AS (
    SELECT r.r_name, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    s.s_name,
    ns.n_name,
    rs.r_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    SUM(os.total_order_value) AS total_spent,
    AVG(s.s_acctbal) OVER (PARTITION BY ns.n_name) AS avg_supplier_acctbal,
    CASE 
        WHEN ps.ps_availqty IS NULL THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status,
    COUNT(os.total_order_value) OVER (PARTITION BY ns.n_name) AS order_count
FROM SupplierHierarchy s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN OrderSummary os ON os.o_custkey = s.s_nationkey
JOIN nation ns ON s.s_nationkey = ns.n_nationkey
JOIN RegionNation rs ON ns.n_regionkey = rs.n_name
GROUP BY s.s_name, ns.n_name, rs.r_name, ps.ps_availqty, ps.ps_supplycost
ORDER BY total_spent DESC
LIMIT 10;
