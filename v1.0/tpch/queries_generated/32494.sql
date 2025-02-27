WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > 5000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, MAX(ps.ps_supplycost) AS max_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
)
SELECT 
    CONCAT(n.n_name, ' has ', ns.supplier_count, ' suppliers and ', ns.customer_count, ' customers.') AS summary,
    p.p_name,
    sh.s_name,
    oc.total_spent,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY oc.total_spent DESC) AS rank
FROM NationSummary ns
JOIN nation n ON ns.n_name = n.n_name
JOIN PartDetails p ON p.max_supply_cost > (SELECT AVG(max_supply_cost) FROM PartDetails)
JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
JOIN OrderedCustomers oc ON oc.c_custkey = sh.s_suppkey
WHERE oc.total_spent IS NOT NULL
  AND n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'N%')
ORDER BY n.n_name, rank
LIMIT 10;
