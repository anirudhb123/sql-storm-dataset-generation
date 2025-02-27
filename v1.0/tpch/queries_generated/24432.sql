WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal + sh.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartAnalysis AS (
    SELECT p.p_partkey, p.p_name,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) / NULLIF(SUM(ps.ps_supplycost), 0) AS avg_supply_efficiency
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerSpend AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT pa.p_partkey, pa.p_name, pa.supplier_count,
           COALESCE(cs.total_spent, 0) AS total_spent,
           cs.spend_rank,
           sh.s_name AS supplier_name
    FROM PartAnalysis pa
    FULL OUTER JOIN CustomerSpend cs ON pa.supplier_count > 0
    LEFT JOIN SupplierHierarchy sh ON cs.total_spent > 1000 AND sh.level <= 3
)
SELECT FR.p_partkey, FR.p_name, FR.supplier_count,
       FR.total_spent, FR.spend_rank,
       CASE WHEN FR.supplier_name IS NOT NULL THEN FR.supplier_name 
            ELSE 'No suppliers' END AS resolved_supplier_name,
       (FR.total_spent * NULLIF(pa.avg_supply_efficiency, 0)) AS adjusted_spending
FROM FinalReport FR
LEFT JOIN PartAnalysis pa ON FR.p_partkey = pa.p_partkey
WHERE (FR.total_spent > 500 OR FR.supplier_count > 10)
  AND (FR.spend_rank IS NULL OR FR.spend_rank <= 5)
ORDER BY FR.total_spent DESC, FR.supplier_count ASC, FR.p_name;
