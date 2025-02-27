WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey != sh.s_suppkey
    WHERE s.s_acctbal > 5000
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderkey
), PartSupplier AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    ps.p_partkey,
    CONCAT(p.p_name, ' (', p.p_size, ')') AS part_description,
    COALESCE(os.total_revenue, 0) AS order_revenue,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders' 
        ELSE CAST(co.order_count AS VARCHAR) 
    END AS customer_order_status,
    sh.level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN OrderSummary os ON p.p_partkey = os.o_orderkey
LEFT JOIN CustomerOrders co ON co.c_custkey = sh.s_suppkey
WHERE sh.level > 1
ORDER BY r.r_name, n.n_name, order_revenue DESC, sh.s_name;
