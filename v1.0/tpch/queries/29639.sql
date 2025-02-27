WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE LENGTH(p.p_name) > 10 LIMIT 1) LIMIT 1)
    WHERE sh.level < 5
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING LENGTH(p.p_name) > 10
)
SELECT sh.s_name AS Supplier_Name, sh.s_address AS Supplier_Address, ps.p_name AS Part_Name, ps.supplier_count, ps.total_cost
FROM SupplierHierarchy sh
JOIN PartSummary ps ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY ps.total_cost DESC, ps.supplier_count DESC;
