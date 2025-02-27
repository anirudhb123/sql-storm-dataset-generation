WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey AND s.s_acctbal < sh.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_revenue) AS national_revenue
    FROM nation n
    LEFT JOIN OrderSummary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN 
        (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN 
            (SELECT l.l_orderkey FROM lineitem l)))
    )
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COALESCE(nr.national_revenue, 0) AS revenue_by_nation
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN NationRevenue nr ON sh.s_nationkey = nr.n_nationkey
WHERE p.p_size BETWEEN 10 AND 20
AND p.p_mfgr LIKE 'Manufacturer%'
AND NOT EXISTS (
    SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R'
)
GROUP BY p.p_name, nr.national_revenue
ORDER BY revenue_by_nation DESC, supplier_count DESC;
