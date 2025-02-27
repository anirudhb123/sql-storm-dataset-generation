WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(od.total_price) AS total_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT r.r_name, SUM(ns.total_revenue) AS revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationSummary ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_name
    HAVING SUM(ns.total_revenue) > 100000
)
SELECT DISTINCT 
    p.p_name,
    p.p_brand,
    ps.ps_supplycost,
    sh.level,
    tr.revenue
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN TopRegions tr ON sh.s_nationkey = tr.r_name
WHERE ps.ps_availqty > 0
AND (p.p_mfgr LIKE 'Manufacturer A%' OR p.p_mfgr LIKE 'Manufacturer B%')
ORDER BY tr.revenue DESC, sh.level ASC;
