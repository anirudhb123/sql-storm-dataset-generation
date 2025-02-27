WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    INNER JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COALESCE(NR.r_name, 'Unknown Region') AS region,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(COALESCE(os.net_revenue, 0)) AS total_revenue,
    SUM(CASE WHEN cos.total_orders IS NULL THEN 0 ELSE cos.total_orders END) AS total_customers,
    AVG(cos.avg_order_value) AS avg_order_value,
    SH.level AS supplier_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy SH ON ps.ps_suppkey = SH.s_suppkey
LEFT JOIN OrderSummary os ON ps.ps_partkey = os.o_orderkey
LEFT JOIN NationRegion NR ON ps.ps_suppkey = NR.n_nationkey
LEFT JOIN CustomerOrderStats cos ON NR.n_nationkey = cos.c_custkey
GROUP BY p.p_name, NR.r_name, SH.level
ORDER BY total_revenue DESC, supplier_count DESC;
