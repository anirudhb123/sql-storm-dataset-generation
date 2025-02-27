
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
PopularParts AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY l.l_partkey
    ORDER BY total_quantity DESC
    LIMIT 10
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE((SELECT MAX(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey), 0) AS max_supply_cost,
    COALESCE((SELECT COUNT(DISTINCT c.c_custkey) FROM TopCustomers tc JOIN customer c ON tc.c_custkey = c.c_custkey WHERE tc.total_spent > 10000), 0) AS total_high_spenders,
    SUM(l.l_extendedprice) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN PopularParts pp ON pp.l_partkey = p.p_partkey
LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
WHERE p.p_size IS NOT NULL AND p.p_retailprice > 10.00
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY total_revenue DESC, p.p_name ASC;
