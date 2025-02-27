WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey
    )

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY o.o_orderkey, o.o_orderdate
),
MetallicParts AS (
    SELECT p.p_partkey, p.p_name, p.p_container
    FROM part p
    WHERE p.p_size > 5 AND p.p_type LIKE '%metal%'
),
PartsWithSuppliers AS (
    SELECT pp.p_partkey, pp.p_name, ps.ps_availqty, ps.ps_supplycost, s.s_name
    FROM MetallicParts pp
    JOIN partsupp ps ON pp.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT ch.c_custkey) AS num_customers,
    SUM(IFNULL(os.total_revenue, 0)) AS total_revenue_generated,
    SUM(SPH.s_acctbal) AS total_supplier_acctbal
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN OrderSummary os ON ch.c_custkey = os.o_orderkey
LEFT JOIN SupplierHierarchy SPH ON n.n_nationkey = SPH.s_nationkey
LEFT JOIN PartsWithSuppliers ppws ON ppws.p_partkey = (SELECT MIN(p_partkey) FROM part)
GROUP BY r.r_name
HAVING num_customers > 5 AND total_supplier_acctbal IS NOT NULL
ORDER BY total_supplier_acctbal DESC;
