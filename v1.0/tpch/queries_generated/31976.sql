WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 

QualifiedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),

TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(*) AS orders_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN QualifiedOrders qo ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500)
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(*) > 5
    ORDER BY orders_count DESC
    LIMIT 5
)

SELECT 
    n.n_name,
    r.r_name,
    s.s_name,
    sh.level,
    COUNT(qo.o_orderkey) AS order_count,
    SUM(qo.total_revenue) AS total_revenue
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN QualifiedOrders qo ON s.s_suppkey = qo.o_orderkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY n.n_name, r.r_name, s.s_name, sh.level
ORDER BY total_revenue DESC NULLS LAST;
