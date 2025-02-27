WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS hierarchy_path
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_size > 10 ORDER BY p.p_retailprice LIMIT 1)
),

NationStats AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           AVG(c.c_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),

SupplierOrders AS (
    SELECT s.s_suppkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY s.s_suppkey
)

SELECT n.n_name, ns.customer_count, ns.avg_acctbal,
       COALESCE(so.order_count, 0) AS order_count,
       sh.hierarchy_path
FROM NationStats ns
JOIN nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN SupplierOrders so ON so.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10) LIMIT 1)
JOIN SupplierHierarchy sh ON sh.s_suppkey = so.s_suppkey
ORDER BY ns.customer_count DESC, ns.avg_acctbal DESC;
