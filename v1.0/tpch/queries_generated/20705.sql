WITH RECURSIVE SuppHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment,
           CAST(s_name AS VARCHAR(255)) AS full_path,
           0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'U%')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           CONCAT(sh.full_path, ' -> ', s.s_name),
           sh.level + 1
    FROM supplier s
    JOIN SuppHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderStats AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rank,
           o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o_orderkey, o_custkey, o_orderdate, o_orderstatus
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(os.revenue), 0) AS total_revenue
    FROM customer c
    LEFT JOIN OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Top50Customers AS (
    SELECT c.c_custkey, c.c_name, cr.total_revenue,
           DENSE_RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN CustomerRevenue cr ON c.c_custkey = cr.c_custkey
    WHERE cr.total_revenue > 1000
)
SELECT s.s_name, s.s_acctbal, sh.full_path, t.c_name,
       t.total_revenue, CASE WHEN t.revenue_rank IS NULL THEN 'Not Ranked' ELSE 'Ranked' END AS rank_status
FROM supplier s
LEFT JOIN SuppHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN Top50Customers t ON s.s_nationkey = t.c_custkey
WHERE (s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)) 
   OR (s.s_comment IS NOT NULL AND LENGTH(s.s_comment) > 10)
ORDER BY t.total_revenue DESC, s.s_name ASC
FETCH FIRST 100 ROWS ONLY;
