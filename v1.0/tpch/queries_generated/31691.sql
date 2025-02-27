WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(co.total_spent) AS total_revenue,
    ps.p_partkey, 
    ps.total_available,
    ps.avg_supplycost,
    CASE 
        WHEN SUM(co.order_count) > 100 THEN 'High Frequent'
        WHEN SUM(co.order_count) BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Low Frequent'
    END AS customer_frequency
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT OUTER JOIN PartSupplier ps ON ps.p_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_availqty > 
        (SELECT AVG(ps_availqty) 
         FROM partsupp)
)
WHERE c.c_acctbal IS NOT NULL
GROUP BY n.n_name, ps.p_partkey, ps.total_available, ps.avg_supplycost
HAVING SUM(co.total_spent) > 50000
ORDER BY total_revenue DESC, unique_customers DESC;
