WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE s.s_acctbal > sh.s_acctbal * 0.8
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
SupplierOrderSummary AS (
    SELECT sh.s_name, COUNT(DISTINCT od.o_orderkey) AS order_count, SUM(od.total_revenue) AS total_revenue
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY sh.s_name
)
SELECT sos.s_name,
       sos.order_count,
       sos.total_revenue,
       COALESCE(sos.total_revenue / NULLIF(sos.order_count, 0), 0) AS avg_revenue_per_order,
       ROW_NUMBER() OVER (ORDER BY sos.total_revenue DESC) AS rank
FROM SupplierOrderSummary sos
WHERE sos.order_count > 10
ORDER BY avg_revenue_per_order DESC;
