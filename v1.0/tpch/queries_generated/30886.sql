WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 8000
),
AggregateSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SUM(a.total_spent), 0) AS total_customer_expenditure,
    AVG(sh.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT ps.p_partkey) AS unique_parts_supply,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN AggregateSales a ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = a.c_custkey LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50)
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT a.total_spent) > 5 AND AVG(sh.level) < 2
ORDER BY total_customer_expenditure DESC, avg_supplier_balance ASC;
