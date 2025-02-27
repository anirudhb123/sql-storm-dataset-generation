WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
)
, FilteredCust AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING' AND c.c_acctbal > 1000
)
, RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(DAY, -30, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name,
    r.r_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(COALESCE(sh.s_acctbal, 0)) AS total_acct_balance,
    SUM(rol.total_value) AS recent_order_value
FROM 
    part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RecentOrders rol ON s.s_suppkey = rol.o_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND r.r_name IS NOT NULL
    AND (sh.level IS NULL OR sh.level < 3)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > (SELECT COUNT(*) FROM FilteredCust)
ORDER BY 
    total_acct_balance DESC, p.p_name
FETCH FIRST 100 ROWS ONLY;
