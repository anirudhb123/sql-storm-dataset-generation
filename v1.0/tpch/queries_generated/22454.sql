WITH RecursiveSupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rh.level + 1
    FROM supplier s
    JOIN RecursiveSupplierHierarchy rh ON s.s_nationkey = rh.s_suppkey
    WHERE rh.level < 5
), 
PartWithHighAvailability AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100 AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent, c.order_count
    FROM CustomerOrders c
    WHERE c.rnk <= 10
), 
PartSupplierJoin AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM PartWithHighAvailability p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT 
    r.r_name,
    ns.n_name,
    CONCAT('Supplier: ', sh.s_name, ', Part: ', p.p_name, ', Total Value: ', ps.total_value) AS description
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN RecursiveSupplierHierarchy sh ON ns.n_nationkey = sh.s_suppkey
JOIN TopCustomers tc ON tc.c_custkey = sh.s_suppkey
JOIN PartSupplierJoin ps ON ps.p_partkey IN (
    SELECT p_partkey FROM part WHERE p_size BETWEEN 1 AND 10 
    EXCEPT 
    SELECT p_partkey FROM part WHERE p_comment IS NULL
)
WHERE sh.level = 3 
AND (sh.s_acctbal IS NULL OR sh.s_acctbal < 5000)
ORDER BY r.r_name, ns.n_name, ps.total_value DESC;
