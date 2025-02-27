WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
CustomerOrderMetrics AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent, 
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rh.r_name,
    COUNT(DISTINCT ch.c_custkey) AS total_customers,
    SUM(co.total_spent) AS total_spent_by_customers,
    AVG(co.avg_order_value) AS average_order_value_per_customer,
    (SELECT COUNT(*) FROM PartSupplier ps WHERE ps.ps_supplycost < 100) AS cheap_parts_count,
    ROW_NUMBER() OVER (PARTITION BY rh.r_name ORDER BY SUM(co.total_spent) DESC) AS region_rank
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN CustomerOrderMetrics co ON n.n_nationkey = co.c_custkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE 
    co.order_count > 0 
    AND sh.s_acctbal IS NOT NULL
GROUP BY rh.r_name
HAVING SUM(co.total_spent) > 10000
ORDER BY region_rank, total_spent_by_customers DESC;
