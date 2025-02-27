WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS num_suppliers, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FrequentPurchases AS (
    SELECT cs.c_custkey, COUNT(l.l_orderkey) AS purchase_frequency
    FROM CustomerSummary cs
    JOIN orders o ON cs.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY cs.c_custkey
    HAVING COUNT(l.l_orderkey) > 10
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    AVG(p.avg_supply_cost) AS average_cost_per_part,
    MAX(fp.purchase_frequency) AS max_purchase_frequency
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplierSummary p ON p.num_suppliers >= 5
LEFT JOIN FrequentPurchases fp ON n.n_nationkey = fp.c_custkey
GROUP BY r.r_name
ORDER BY total_suppliers DESC, average_cost_per_part ASC
LIMIT 10;
