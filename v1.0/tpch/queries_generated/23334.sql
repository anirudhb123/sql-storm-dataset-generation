WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000.00
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.depth + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal IS NOT NULL AND sp.s_acctbal < sh.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
    AND c.c_name LIKE 'A%'
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY o.o_orderkey
),
AggregatedData AS (
    SELECT ph.p_partkey, SUM(ps.ps_supplycost) as total_supply_cost, 
           COUNT(DISTINCT o.o_orderkey) as order_count,
           AVG(l.l_discount) AS avg_discount
    FROM part ph
    LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ph.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY ph.p_partkey
)
SELECT rh.r_name, AVG(sh.depth) AS avg_supplier_depth, 
       AVG(ad.total_supply_cost) AS avg_supply_cost, 
       SUM(CASE WHEN hc.c_custkey IS NOT NULL THEN 1 ELSE 0 END) AS high_value_customer_count
FROM region rh
FULL OUTER JOIN SupplierHierarchy sh ON sh.s_nationkey = rh.r_regionkey
LEFT JOIN HighValueCustomers hc ON hc.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey)
JOIN AggregatedData ad ON ad.total_supply_cost > sh.depth * 1000
WHERE rh.r_name IS NOT NULL AND (sh.depth IS NULL OR sh.depth > 2)
GROUP BY rh.r_name
HAVING COUNT(*) > 1
ORDER BY avg_supplier_depth DESC, high_value_customer_count DESC
LIMIT 10
OFFSET 5;
