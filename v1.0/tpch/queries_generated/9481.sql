WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    WHERE s.s_acctbal > 1000.00 AND sh.level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    AVG(sh.s_acctbal) AS avg_account_balance,
    os.total_revenue
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN OrderStats os ON os.total_revenue > 5000.00
GROUP BY r.r_name, n.n_name, os.total_revenue
ORDER BY region, nation, avg_account_balance DESC;
