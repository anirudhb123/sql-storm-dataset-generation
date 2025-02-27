WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA') 
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)

SELECT 
    nh.n_name AS NationName,
    ss.s_name AS SupplierName,
    os.total_revenue,
    fc.c_name AS CustomerName,
    fc.c_acctbal AS CustomerAccountBalance
FROM NationHierarchy nh
FULL OUTER JOIN SupplierSummary ss ON nh.n_nationkey = ss.s_suppkey
FULL OUTER JOIN OrderStatistics os ON ss.s_suppkey = os.o_orderkey
LEFT JOIN FilteredCustomers fc ON fc.c_custkey = os.o_orderkey
WHERE ss.total_available IS NOT NULL OR os.total_revenue IS NOT NULL
ORDER BY nh.level, ss.total_available DESC NULLS LAST;