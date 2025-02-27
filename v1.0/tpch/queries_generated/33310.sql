WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ph.region, 
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RecentOrders oh ON l.l_orderkey = oh.o_orderkey
LEFT JOIN (
    SELECT n.n_nationkey, r.r_name AS region
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
) ph ON l.l_suppkey = ph.n_nationkey
LEFT JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN TopSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00 
  AND (l.l_discount IS NULL OR l.l_discount < 0.1)
GROUP BY p.p_partkey, p.p_name, ph.region
HAVING COUNT(DISTINCT oh.o_orderkey) > 10
ORDER BY total_quantity DESC, avg_price ASC;
