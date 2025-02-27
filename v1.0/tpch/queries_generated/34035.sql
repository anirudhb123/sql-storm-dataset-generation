WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderAggregation AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate < CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY o.o_custkey
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, COALESCE(oa.total_spent, 0) AS total_spent
    FROM customer c
    LEFT JOIN OrderAggregation oa ON c.c_custkey = oa.o_custkey
),
NationPerformance AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS num_customers, 
           SUM(cs.total_spent) AS total_spending,
           AVG(cs.total_spent) AS avg_spending,
           MAX(cs.total_spent) AS max_spending
    FROM nation n
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN CustomerSpending cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent IS NOT NULL
    GROUP BY n.n_name
),
TopRegions AS (
    SELECT r.r_name, SUM(np.total_spending) AS region_spending
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationPerformance np ON n.n_name = np.n_name
    GROUP BY r.r_name
    HAVING SUM(np.total_spending) > 100000
    ORDER BY region_spending DESC
)
SELECT sr.s_name, sr.s_acctbal, tr.r_name, tr.region_spending
FROM SupplierHierarchy sr
JOIN TopRegions tr ON sr.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = tr.r_name)
WHERE sr.level < 2
ORDER BY sr.s_acctbal DESC, tr.region_spending DESC;
