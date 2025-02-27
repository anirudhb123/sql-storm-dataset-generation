WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s2 ON sh.s_nationkey = s2.s_nationkey AND sh.s_suppkey <> s2.s_suppkey
    WHERE s2.s_acctbal > sh.s_acctbal
),
DenseRankedOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_totalprice > 500
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomersWithOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    n.n_name AS nation, 
    SUM(so.total_spent) AS total_spent, 
    AVG(so.order_count) AS avg_orders,
    MAX(l.l_extendedprice - l.l_discount * l.l_extendedprice) AS max_price_after_discount,
    COUNT(DISTINCT sh.s_suppkey) AS distinct_suppliers
FROM nation n
LEFT JOIN CustomersWithOrders so ON n.n_nationkey = so.c_nationkey
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
LEFT JOIN SupplierHierarchy sh ON sh.level <= 3
WHERE n.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Middle%')
GROUP BY n.n_name
HAVING total_spent > 10000
ORDER BY total_spent DESC;
