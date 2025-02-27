WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 2500.00

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, ch.c_nationkey, level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND ch.level < 5
), 
TotalRevenue AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
SupplierMetrics AS (
    SELECT ps.ps_partkey, s.s_suppkey, SUM(ps.ps_availqty) AS total_available, AVG(s.s_acctbal) AS avg_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
),
NationRevenue AS (
    SELECT n.n_nationkey, SUM(COALESCE(tr.total_revenue, 0)) AS nation_revenue
    FROM nation n
    LEFT JOIN TotalRevenue tr ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tr.o_custkey)
    GROUP BY n.n_nationkey
)
SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COALESCE(n.nation_revenue, 0) AS total_nation_revenue,
    STRING_AGG(DISTINCT ch.c_name, '; ') AS customer_names
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN NationRevenue n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN CustomerHierarchy ch ON ch.c_custkey = o.o_custkey
WHERE p.p_size > 20 AND n.nation_revenue IS NOT NULL
GROUP BY p.p_name, n.nation_revenue
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000.00
ORDER BY part_revenue DESC;
