WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TotalSupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
PartSubquery AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(MAX(l.l_discount), 0) AS max_discount,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, 
       psc.total_cost, s.s_name AS top_supplier,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rank
FROM PartSubquery p
JOIN TotalSupplierCosts psc ON p.p_partkey = psc.ps_partkey
LEFT JOIN SupplierHierarchy s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey LIMIT 1)
WHERE p.max_discount > 0.10 AND p.total_quantity > 100
ORDER BY p.p_partkey, rank
LIMIT 50;
