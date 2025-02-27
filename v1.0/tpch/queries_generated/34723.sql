WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopCountries AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
    ORDER BY customer_count DESC
    LIMIT 5
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    sh.s_name AS supplier_name,
    COALESCE(ph.total_cost, 0) AS total_part_supply_cost,
    od.total_revenue AS order_revenue,
    tc.n_name AS top_country,
    ROW_NUMBER() OVER (PARTITION BY tc.n_name ORDER BY od.total_revenue DESC) AS revenue_rank
FROM SupplierHierarchy sh
LEFT JOIN PartSuppliers ph ON sh.s_suppkey = ph.p_partkey
LEFT JOIN OrderDetails od ON od.o_orderkey = sh.s_suppkey
JOIN TopCountries tc ON sh.s_suppkey = tc.customer_count
WHERE sh.level > 0 AND sh.s_name LIKE '%Supplier%'
ORDER BY rc.level, total_part_supply_cost DESC;
