WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal >= 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_suppkey
),
PartPricing AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_volume
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    n.n_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(p.avg_supplycost) AS total_avg_cost,
    SUM(co.total_spent) AS total_customer_spending,
    SUM(ns.sales_volume) AS nation_sales_volume
FROM NationSales ns
JOIN CustomerOrders co ON ns.n_nationkey = co.c_custkey
JOIN PartPricing p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
GROUP BY n.n_name
HAVING SUM(ns.sales_volume) > 100000
ORDER BY SUM(ns.sales_volume) DESC;
