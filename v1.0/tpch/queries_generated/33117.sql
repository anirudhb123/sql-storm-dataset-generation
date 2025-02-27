WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT n.n_name, 
       COALESCE(ns.supplier_count, 0) AS total_suppliers,
       (SELECT COUNT(DISTINCT o.o_orderkey) 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
        AND l.l_discount > 0.1) AS discounted_orders,
       SUM(od.total_revenue) AS total_revenue,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(od.total_revenue) DESC) AS revenue_rank
FROM nation n
LEFT JOIN NationStats ns ON n.n_name = ns.n_name
LEFT JOIN OrderDetails od ON od.o_orderkey IS NOT NULL
GROUP BY n.n_name, ns.supplier_count
ORDER BY total_revenue DESC
LIMIT 10;
