WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
), 
MaxOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
PartInfo AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_size, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_size
),
FilteredCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal BETWEEN 100.00 AND 500.00
)
SELECT 
    o.o_orderdate,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN FilteredCustomers fc ON c.c_custkey = fc.c_custkey
JOIN PartInfo pi ON l.l_partkey = pi.p_partkey
GROUP BY o.o_orderdate, n.n_name, sh.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
ORDER BY n.n_name, total_revenue DESC
LIMIT 50;
