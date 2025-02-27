WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 0 AND sh.level < 5
),
AggregatedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
QualifiedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    s.s_name AS supplier_name,
    p.total_available,
    p.avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS finalized_order_value,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ':', c.c_name), '; ') AS customers_in_nation
FROM SupplierHierarchy s
LEFT JOIN AggregatedParts p ON s.s_nationkey = p.p_partkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN QualifiedCustomers c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY s.s_name, p.total_available, p.avg_supply_cost
HAVING SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) > 1000
ORDER BY customer_count DESC;
