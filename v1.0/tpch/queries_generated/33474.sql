WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.s_name,
    np.r_name,
    ps.total_availqty,
    ps.avg_supplycost,
    os.total_revenue,
    os.customer_count,
    cr.rank
FROM SupplierHierarchy sr
LEFT JOIN NationRegion np ON sr.s_nationkey = np.n_nationkey
INNER JOIN PartSupplier ps ON sr.s_suppkey = ps.p_partkey
FULL OUTER JOIN OrderSummary os ON sr.s_suppkey = os.o_orderkey
JOIN CustomerRanking cr ON os.customer_count > cr.rank
WHERE ps.total_availqty > (SELECT AVG(total_availqty) FROM PartSupplier)
AND np.r_name IS NOT NULL
ORDER BY sr.level, os.total_revenue DESC, ps.avg_supplycost ASC;
